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

    desc 'describe [PROJECT_SLUG]', 'describe'
    method_option :output, type: :string, aliases: '-o', enum: ['json', 'pretty'], default: 'json'
    def describe(project_slug)
      run('describe', project_slug: project_slug)
    end

    private

    def run(command, project_slug: nil)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

      case command
      when 'list'
        handle_list_command
      when 'describe'
        handle_describe_command(project_slug)
      end
    end

    def handle_describe_command(project_slug)
      response = describe_project(ConfigFile.read_option(:server), project_slug)

      if ResponseHelper.ok?(response)
        handle_succeed_describe_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_describe_response(response)
      project = response[:body][:project]
      project[:deployments] = select_active_deployments(project[:deployments])
      Uffizzi.ui.output_format = options[:output]
      Uffizzi.ui.describe_project(project)
    end

    def select_active_deployments(deployments)
      deployments.select { |deployment| deployment[:state] == 'active' }
    end

    def handle_list_command
      server = ConfigFile.read_option(:server)
      response = fetch_projects(server)

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_list_response(response)
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
