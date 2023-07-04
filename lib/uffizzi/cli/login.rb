# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/helpers/project_helper'
require 'uffizzi/helpers/login_helper'
require 'uffizzi/helpers/config_helper'
require 'uffizzi/clients/api/api_client'
require 'launchy'
require 'securerandom'
require 'tty-prompt'

module Uffizzi
  class Cli::Login
    include ApiClient

    def initialize(options)
      @options = options
      @server = Uffizzi::LoginHelper.set_server(@options)
    end

    def run
      return perform_email_login if @options[:email]

      perform_browser_login
    end

    private

    def perform_email_login
      Uffizzi.ui.say('Login to Uffizzi server.')
      username =  Uffizzi::LoginHelper.set_username(@options)
      password =  Uffizzi::LoginHelper.set_password
      params = Uffizzi::LoginHelper.prepare_request_params(username, password)
      response = create_session(@server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, username)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def perform_browser_login
      session_id = SecureRandom.uuid
      response = create_access_token(@server, session_id)
      return handle_failed_response(response) unless ResponseHelper.created?(response)

      url = browser_sign_in_url(@server, session_id)
      open_browser(url)

      loop do
        response = get_access_token(@server, session_id)

        if ResponseHelper.ok?(response)
          break handle_token_success(response)
        elsif ResponseHelper.unprocessable_entity?(response)
          break Uffizzi.ui.say('The session has expired. Please try again.')
        else
          sleep(3)
        end
      end
    end

    def handle_token_success(response)
      ConfigFile.write_option(:server, @server)
      token = response[:body][:access_token]
      Uffizzi::Token.delete
      Uffizzi::Token.write(token)
      Uffizzi.ui.say('Login successfull')

      set_current_account_and_project
    end

    def open_browser(url)
      Launchy.open(url)
    rescue StandardError
      Uffizzi.ui.say('Login to Uffizzi server.')
      Uffizzi.ui.say(url)
    end

    def handle_succeed_response(response, username)
      ConfigFile.write_option(:server, @server)
      ConfigFile.write_option(:username, username)
      ConfigFile.write_option(:cookie, response[:headers])
      Uffizzi.ui.say('Login successfull')

      if ENV.fetch('CI_PIPELINE_RUN', false)
        account = response[:body][:user][:default_account]
        return ConfigFile.write_option(:account, Uffizzi::ConfigHelper.account_config(account[:id]))
      end

      set_current_account_and_project
    end

    def set_current_account_and_project
      current_account_id = ConfigFile.read_option(:account, :id)
      current_project_slug = ConfigFile.read_option(:project)

      unless current_account_id
        account_id = set_account
        return set_project(account_id)
      end

      return if current_project_slug && project_exists?(current_account_id, current_project_slug)

      set_project(account_id)
    end

    def project_exists?(account_id, project_slug)
      check_project_response = fetch_account_projects(@server, account_id)
      return ResponseHelper.handle_failed_response(check_project_response) unless ResponseHelper.ok?(check_project_response)

      projects = check_project_response[:body][:projects]
      slugs = projects.map { |project| project[:slug] }

      slugs.include?(project_slug)
    end

    def set_account
      accounts_response = fetch_accounts(@server)
      accounts = accounts_response[:body][:accounts]
      if accounts.length == 1
        current_account = accounts.first
        ConfigFile.write_option(:account, Uffizzi::ConfigHelper.account_config(current_account[:id], current_account[:name]))
        return current_account[:id]
      end
      question = 'Select an account:'
      choices = accounts.map do |account|
        { name: account[:name], value: account[:id] }
      end
      account_id = Uffizzi.prompt.select(question, choices)
      account_name = accounts.detect { |account| account[:id] == account_id }[:name]

      ConfigFile.write_option(:account, Uffizzi::ConfigHelper.account_config(account_id, account_name))

      account_id
    end

    def set_project(account_id)
      projects_response = fetch_account_projects(@server, account_id)
      projects = projects_response[:body][:projects]
      question = 'Select a project or create a new project:'
      choices = projects.map do |project|
        { name: project[:name], value: project[:slug] }
      end
      all_choices = choices + [{ name: 'Create a new project', value: nil }]
      answer = Uffizzi.prompt.select(question, all_choices)
      return create_new_project unless answer

      ConfigFile.write_option(:project, answer)
    end

    def create_new_project
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

      account_id = ConfigFile.read_option(:account, :id)
      response = create_project(@server, account_id, params)

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
