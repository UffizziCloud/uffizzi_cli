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
    method_option :filter, required: false, type: :string, aliases: '-f'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def list
      run('list')
    end

    desc 'create [COMPOSE_FILE]', 'Create a preview'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'github-action']
    method_option :"set-labels", required: false, type: :string, aliases: '-s'
    method_option :"creation-source", required: false, type: :string
    def create(file_path = nil)
      run('create', file_path: file_path)
    end

    desc 'uffizzi preview update [DEPLOYMENT_ID] [COMPOSE_FILE]', 'Update a preview'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'github-action']
    method_option :"set-labels", required: false, type: :string, aliases: '-s'
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
      Uffizzi.ui.output_format = options[:output]
      raise Uffizzi::Error.new('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless CommandService.project_set?(options)

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'list'
        handle_list_command(project_slug, options[:filter])
      when 'create'
        handle_create_command(file_path, project_slug, options[:"set-labels"], options[:"creation-source"])
      when 'update'
        handle_update_command(deployment_name, file_path, project_slug, options[:"set-labels"])
      when 'delete'
        handle_delete_command(deployment_name, project_slug)
      when 'describe'
        handle_describe_command(deployment_name, project_slug)
      when 'events'
        handle_events_command(deployment_name, project_slug)
      end
    end

    def handle_list_command(project_slug, filter)
      parsed_filter = filter.nil? ? {} : build_filter_params(filter)
      response = fetch_deployments(ConfigFile.read_option(:server), project_slug, parsed_filter)

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command(file_path, project_slug, labels, creation_source)
      params = prepare_params(file_path, labels, creation_source)

      response = create_deployment(ConfigFile.read_option(:server), project_slug, params)

      if !ResponseHelper.created?(response)
        ResponseHelper.handle_failed_response(response)
      end

      deployment = response[:body][:deployment]
      Uffizzi.ui.say("Preview with ID deployment-#{deployment[:id]} was created.")

      success = PreviewService.run_containers_deploy(project_slug, deployment)

      display_deployment_data(deployment, success)
    rescue SystemExit, Interrupt, SocketError
      deployment_id = response[:body][:deployment][:id]
      handle_preview_interruption(deployment_id, ConfigFile.read_option(:server), project_slug)
    end

    def handle_update_command(deployment_name, file_path, project_slug, labels)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      raise Uffizzi::Error.new("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      params = prepare_params(file_path, labels)
      response = update_deployment(ConfigFile.read_option(:server), project_slug, deployment_id, params)

      if !ResponseHelper.ok?(response)
        ResponseHelper.handle_failed_response(response)
      end

      deployment = response[:body][:deployment]
      Uffizzi.ui.say("Preview with ID deployment-#{deployment_id} was updated.")

      success = PreviewService.run_containers_deploy(project_slug, deployment)

      display_deployment_data(deployment, success)
    rescue SystemExit, Interrupt, SocketError
      deployment_id = response[:body][:deployment][:id]
      handle_preview_interruption(deployment_id, ConfigFile.read_option(:server), project_slug)
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
      Uffizzi.ui.output_format = Uffizzi::UI::Shell::PRETTY_JSON
      Uffizzi.ui.say(response[:body][:events])
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

      if Uffizzi.ui.output_format.nil?
        deployments = deployments.reduce('') do |acc, deployment|
          "#{acc}deployment-#{deployment[:id]}\n"
        end.strip
      end
      Uffizzi.ui.say(deployments)
    end

    def handle_succeed_delete_response(deployment_id)
      Uffizzi.ui.say("Preview deployment-#{deployment_id} deleted")
    end

    def handle_succeed_describe_response(response)
      deployment = response[:body][:deployment]
      deployment[:containers] = deployment[:containers].map do |container|
        unless container[:secret_variables].nil?
          container[:secret_variables] = hide_secrets(container[:secret_variables])
        end

        container
      end
      deployment_data = deployment.reduce('') { |acc, (key, value)| "#{acc}#{key}: #{value}\n" }.strip
      Uffizzi.ui.say(deployment_data)
    end

    def hide_secrets(secret_variables)
      secret_variables.map do |secret_variable|
        secret_variable[:value] = '******'

        secret_variable
      end
    end

    def prepare_params(file_path, labels, creation_source = nil)
      compose_file_params = file_path.nil? ? {} : build_compose_file_params(file_path)
      metadata_params = labels.nil? ? {} : build_metadata_params(labels)
      token = ConfigFile.read_option(:token)
      extra_params = token.nil? ? {} : { token: token }
      params = compose_file_params.merge(metadata_params)
      params.merge(extra_params, { creation_source: creation_source })
    end

    def handle_preview_interruption(deployment_id, server, project_slug)
      deletion_response = delete_deployment(server, project_slug, deployment_id)
      deployment_name = "deployment-#{deployment_id}"
      preview_deletion_message = if ResponseHelper.no_content?(deletion_response)
        "The preview #{deployment_name} has been disabled."
      else
        "Couldn't disable the deployment #{deployment_name} - please disable maually."
      end

      raise Uffizzi::Error.new("The preview creation was interrupted. #{preview_deletion_message}")
    end

    def display_deployment_data(deployment, success)
      if Uffizzi.ui.output_format.nil?
        Uffizzi.ui.say('Done')
        preview_url = "https://#{deployment[:preview_url]}"
        Uffizzi.ui.say(preview_url) if success
      else
        deployment_data = build_deployment_data(deployment)
        Uffizzi.ui.say(deployment_data)
      end
    end

    def build_deployment_data(deployment)
      url_server = ConfigFile.read_option(:server)

      {
        id: "deployment-#{deployment[:id]}",
        url: "https://#{deployment[:preview_url]}",
        containers_uri: "#{url_server}/projects/#{deployment[:project_id]}/deployments/#{deployment[:id]}/containers",
      }
    end

    def build_compose_file_params(file_path)
      begin
        compose_file_data = EnvVariablesService.substitute_env_variables(File.read(file_path))
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

    def build_metadata_params(labels)
      {
        metadata: {
          'labels' => parse_params(labels, 'Labels'),
        },
      }
    end

    def build_filter_params(filter_params)
      {
        'labels' => parse_params(filter_params, 'Filtering parameters'),
      }
    end

    def parse_params(params, params_type)
      validate_params(params, params_type)
      params.split(' ').reduce({}) do |acc, param|
        stringified_keys, value = param.split('=', 2)
        keys = stringified_keys.split('.', -1)
        inner_pair = { keys.pop => value }
        prepared_param = keys.reverse.reduce(inner_pair) { |res, key| { key => res } }
        merge_params(acc, prepared_param)
      end
    end

    def validate_params(params, params_type)
      params.split(' ').each do |param|
        stringified_keys, value = param.split('=', 2)
        raise Uffizzi::Error.new("#{params_type} were set in incorrect format.") if value.nil? || stringified_keys.nil? || value.empty?

        keys = stringified_keys.split('.', -1)
        raise Uffizzi::Error.new("#{params_type} were set in incorrect format.") if keys.empty? || keys.any?(&:empty?)
      end
    end

    def merge_params(result, param)
      key = param.keys.first
      return result.merge(param) unless result.has_key?(key)

      { key => result[key].merge(merge_params(result[key], param[key])) }
    end
  end
end
