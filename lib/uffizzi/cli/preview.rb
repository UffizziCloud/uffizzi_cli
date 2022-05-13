# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'

module Uffizzi
  class Cli::Preview < Thor
    include ApiClient

    desc 'service', 'Show the preview services info'
    require_relative 'preview/service'
    subcommand 'service', Uffizzi::Cli::Preview::Service
    desc 'list', 'List all previews'
    def list
      run('list')
    end

    desc 'create [COMPOSE_FILE]', 'Create a preview'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'github-action']
    def create(file_path = nil)
      run('create', file_path: file_path)
    end

    desc 'uffizzi preview update [DEPLOYMENT_ID] [COMPOSE_FILE]', 'create'
    def update(deployment_name, file_path)
      run('update', deployment_name: deployment_name, file_path: file_path)
    end

    desc 'delete [DEPLOYMENT_ID]', 'Delete a preview'
    def delete(deployment_name)
      run('delete', deployment_name: deployment_name)
    end

    desc 'describe [DEPLOYMENT_ID]', 'Display details of a preview'
    def describe(deployment_name)
      run('describe', deployment_name: deployment_name)
    end

    desc 'events [DEPLOYMENT_ID]', 'Show the deployment event logs for a preview'
    def events(deployment_name)
      run('events', deployment_name: deployment_name)
    end

    private

    def run(command, file_path: nil, deployment_name: nil)
      unless options[:output].nil?
        Uffizzi.ui.output_format = options[:output]
        Uffizzi.ui.disable_stdout
      end
      raise Uffizzi::Error.new('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless CommandService.project_set?(options)

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(file_path, project_slug)
      when 'update'
        handle_update_command(deployment_name, file_path, project_slug)
      when 'delete'
        handle_delete_command(deployment_name, project_slug)
      when 'describe'
        handle_describe_command(deployment_name, project_slug)
      when 'events'
        handle_events_command(deployment_name, project_slug)
      end
    end

    def handle_list_command(project_slug)
      response = fetch_deployments(ConfigFile.read_option(:server), project_slug)

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command(file_path, project_slug)
      params = file_path.nil? ? {} : prepare_params(file_path)
      response = create_deployment(ConfigFile.read_option(:server), project_slug, params)

      if ResponseHelper.created?(response)
        deployment = response[:body][:deployment]
        success_message = "Preview created with name deployment-#{deployment[:id]}"
        PreviewService.start_deploy_containers(project_slug, deployment, success_message)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_update_command(deployment_name, file_path, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      params = prepare_params(file_path)
      response = update_deployment(ConfigFile.read_option(:server), project_slug, deployment_id, params)

      if ResponseHelper.ok?(response)
        deployment = response[:body][:deployment]
        success_message = "Preview with ID deployment-#{deployment_id} was successfully updated."
        PreviewService.start_deploy_containers(project_slug, deployment, success_message)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_events_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      raise Uffizzi::Error.new("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      response = fetch_events(ConfigFile.read_option(:server), project_slug, deployment_id)

      if ResponseHelper.ok?(response)
        handle_succeed_events_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_events_response(response)
      Uffizzi.ui.pretty_say(response[:body][:events])
    end

    def handle_delete_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      raise Uffizzi::Error.new("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      response = delete_deployment(ConfigFile.read_option(:server), project_slug, deployment_id)

      if ResponseHelper.no_content?(response)
        handle_succeed_delete_response(deployment_id)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_describe_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      raise Uffizzi::Error.new("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      response = describe_deployment(ConfigFile.read_option(:server), project_slug, deployment_id)

      if ResponseHelper.ok?(response)
        handle_succeed_describe_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_list_response(response)
      deployments = response[:body][:deployments] || []
      raise Uffizzi::Error.new('The project has no active deployments') if deployments.empty?

      deployments.each do |deployment|
        Uffizzi.ui.say("deployment-#{deployment[:id]}")
      end
    end

    def handle_succeed_delete_response(deployment_id)
      Uffizzi.ui.say("Preview deployment-#{deployment_id} deleted")
    end

    def handle_succeed_describe_response(response)
      deployment = response[:body][:deployment]
      deployment.each_key do |key|
        Uffizzi.ui.say("#{key}: #{deployment[key]}")
      end
    end

    def prepare_params(file_path)
      begin
        compose_file_data = File.read(file_path)
      rescue Errno::ENOENT => e
        raise Uffizzi::Error.new(e.message)
      end

      compose_file_dir = File.dirname(file_path)
      dependencies = ComposeFileService.parse(compose_file_data, compose_file_dir)
      absolute_path = File.absolute_path(file_path)
      compose_file_params = {
        path: absolute_path,
        content: Base64.encode64(compose_file_data),
        source: absolute_path,
      }

      {
        compose_file: compose_file_params,
        dependencies: dependencies,
      }
    end
  end
end
