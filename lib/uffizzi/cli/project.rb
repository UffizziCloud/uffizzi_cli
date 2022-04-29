# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'

module Uffizzi
  class CLI::Project < Thor
    include ApiClient

    desc 'compose', 'compose'
    method_option :file, required: false, aliases: '-f'
    require_relative 'project/compose'
    subcommand 'compose', Uffizzi::CLI::Project::Compose

    desc 'secret', 'Secrets Actions'
    require_relative 'project/secret'
    subcommand 'secret', Uffizzi::CLI::Project::Secret

    desc 'list', 'list'
    def list
      run('list')
    end

    desc 'set-default PROJECT_SLUG', 'set-default'
    def set_default(project_slug)
      run('set-default', project_slug: project_slug)
    end

    map('set-default' => :set_default)

    private

    def run(command, project_slug: nil)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

      case command
      when 'list'
        handle_list_command
      when 'set-default'
        handle_set_default_command(project_slug)
      end
    end

    def handle_list_command
      server = ConfigFile.read_option(:server)
      response = fetch_projects(server)

      if ResponseHelper.ok?(response)
        handle_succeed_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_response(response)
      projects = response[:body][:projects]
      return Uffizzi.ui.say('No projects related to this email') if projects.empty?

      set_default_project(projects.first) if projects.size == 1
      print_projects(projects)
    end

    def handle_set_default_command(project_slug)
      response = describe_project(ConfigFile.read_option(:server), project_slug)

      if ResponseHelper.ok?(response)
        handle_succeed_set_default_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_set_default_response(response)
      set_default_project(response[:body][:project])
      Uffizzi.ui.say('Default project has been updated.')
    end

    def print_projects(projects)
      projects_list = projects.reduce('') do |acc, project|
        "#{acc}#{project[:slug]}\n"
      end
      Uffizzi.ui.say(projects_list)
    end

    def set_default_project(project)
      ConfigFile.write_option(:project, project[:slug])
    end
  end
end
