# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/helpers/project_helper'

module Uffizzi
  class Cli::Project < Thor
    include ApiClient

    desc 'compose', 'Manage the compose file for a project'
    method_option :file, required: false, aliases: '-f'
    require_relative 'project/compose'
    subcommand 'compose', Uffizzi::Cli::Project::Compose

    desc 'secret', 'Manage secrets for a project'
    require_relative 'project/secret'
    subcommand 'secret', Uffizzi::Cli::Project::Secret

    desc 'list', 'List all projects in the account'
    def list
      run('list')
    end

    desc 'set-default PROJECT_SLUG', 'set-default'
    def set_default(project_slug)
      run('set-default', project_slug: project_slug)
    end

    desc 'describe [PROJECT_SLUG]', 'describe'
    method_option :output, type: :string, aliases: '-o', enum: ['json', 'pretty'], default: 'json'
    def describe(project_slug)
      run('describe', project_slug: project_slug)
    end

    map('set-default' => :set_default)

    method_option :name, required: true
    method_option :slug, default: ''
    method_option :description, required: false
    desc 'create', 'Create a project'
    def create
      run('create')
    end

    desc 'delete [PROJECT_SLUG]', 'Delete a project'
    def delete(project_slug)
      run('delete', project_slug: project_slug)
    end

    private

    def run(command, project_slug: nil)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

      case command
      when 'list'
        handle_list_command
      when 'set-default'
        handle_set_default_command(project_slug)
      when 'create'
        handle_create_command
      when 'delete'
        handle_delete_command(project_slug)
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
      Uffizzi.ui.output_format = options[:output]
      Uffizzi.ui.describe_project(project)
    end

    def handle_list_command
      server = ConfigFile.read_option(:server)
      response = fetch_projects(server)

      if ResponseHelper.ok?(response)
        handle_list_success_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command
      name = options[:name]
      slug = options[:slug].empty? ? Uffizzi::ProjectHelper.generate_slug(name) : options[:slug]
      raise Uffizzi::Error.new('Slug must not content spaces or special characters') unless slug.match?(/^[a-zA-Z0-9\-_]+\Z/i)

      server = ConfigFile.read_option(:server)
      params = {
        name: name,
        description: options[:description],
        slug: slug,
      }
      response = create_project(server, params)

      if ResponseHelper.created?(response)
        handle_create_success_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_delete_command(project_slug)
      server = ConfigFile.read_option(:server)
      response = delete_project(server, project_slug)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Project with slug #{project_slug} was deleted successfully")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_list_success_response(response)
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

    def handle_create_success_response(response)
      project_name = response[:body][:project][:name]

      Uffizzi.ui.say("Project #{project_name} was successfully created")
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
