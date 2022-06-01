# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/helpers/project_helper'
require 'uffizzi/clients/api/api_client'
require 'tty-prompt'

module Uffizzi
  class Cli::Login
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      Uffizzi.ui.say('Login to Uffizzi to view and manage your previews.')
      server = set_server

      username = set_username
      password = set_password
      params = prepare_request_params(username, password)
      response = create_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server, username)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def set_server
      config_server = ConfigFile.option_has_value?(:server) ? ConfigFile.read_option(:server) : nil
      @options[:server] || config_server || Uffizzi.ui.ask('Server: ')
    end

    def set_username
      config_username = ConfigFile.option_has_value?(:username) ? ConfigFile.read_option(:username) : nil
      @options[:username] || config_username || Uffizzi.ui.ask('Username: ')
    end

    def set_password
      ENV['UFFIZZI_PASSWORD'] || Uffizzi.ui.ask('Password: ', echo: false)
    end

    def prepare_request_params(username, password)
      {
        user: {
          email: username,
          password: password,
        },
      }
    end

    def handle_succeed_response(response, server, username)
      account = response[:body][:user][:accounts].first
      return Uffizzi.ui.say('No account related to this email') unless account_valid?(account)

      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:username, username)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, account[:id])

      default_project = ConfigFile.read_option(:project)
      return unless default_project

      check_default_project(default_project, server)
    end

    def account_valid?(account)
      account[:state] == 'active'
    end

    def check_default_project(default_project, server)
      check_project_response = fetch_projects(server)
      return ResponseHelper.handle_failed_response(check_project_response) unless ResponseHelper.ok?(check_project_response)

      projects = check_project_response[:body][:projects]
      slugs = projects.map { |project| project[:slug] }
      return if slugs.include?(default_project)

      question = "Project '#{default_project}' does not exist. Select one of the following projects or create a new project:"
      choices = projects.map do |project|
        { name: project[:name], value: project[:slug] }
      end
      all_choices = choices + [{ name: 'Create a new project', value: nil }]
      answer = Uffizzi.prompt.select(question, all_choices)
      return ConfigFile.write_option(:project, answer) if answer

      create_new_project(server)
    end

    def create_new_project(server)
      project_name = Uffizzi.prompt.ask('Project name: ', required: true)
      generated_slug = Uffizzi::ProjectHelper.generate_slug(project_name)
      project_slug = Uffizzi.prompt.ask('Project slug: ', default: generated_slug)
      raise Uffizzi::Error.new('Slug must not content spaces or special characters') unless project_slug.match?(/^[a-zA-Z0-9\-_]+\Z/i)

      project_description = Uffizzi.prompt.ask('Project desciption: ')

      params = {
        project: {
          name: project_name.strip,
          slug: project_slug,
          description: project_description,
        },
      }

      response = create_project(server, params)

      if ResponseHelper.created?(response)
        handle_create_project_succeess(response)
      else
        handle_create_project_failed(response)
      end
    end

    def handle_create_project_failed(response)
      name_error = response[:body][:errors][:name].first
      name_already_exists = name_error && name_error.first == 'Name already exists'
      message = "Project with name #{project_name} already exists. " \
      'Please run $ uffizzi config to set it as a default project'
      raise Uffizzi::Error.new(message) if name_already_exists

      ResponseHelper.handle_failed_response(response)
    end

    def handle_create_project_succeess(response)
      project = response[:body][:project]

      ConfigFile.write_option(:project, project[:slug])

      Uffizzi.ui.say("Project #{project[:name]} was successfully created")
    end
  end
end
