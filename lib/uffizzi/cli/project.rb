# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'thor'

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

    private

    def run(command)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

      case command
      when 'list'
        handle_list_command
      end
    end

    def handle_list_command
      hostname = ConfigFile.read_option(:hostname)
      response = fetch_projects(hostname)

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
