# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'

module Uffizzi
  class CLI::Preview < Thor
    include ApiClient

    @spinner

    desc 'service', 'service'
    require_relative 'preview/service'
    subcommand 'service', Uffizzi::CLI::Preview::Service

    desc 'list', 'list'
    def list
      run('list')
    end

    desc 'create [COMPOSE_FILE]', 'create'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'github-action']
    def create(file_path = nil)
      run('create', file_path: file_path)
    end

    desc 'delete [DEPLOYMENT_ID]', 'delete'
    def delete(deployment_name)
      run('delete', deployment_name: deployment_name)
    end

    desc 'describe [DEPLOYMENT_ID]', 'describe'
    def describe(deployment_name)
      run('describe', deployment_name: deployment_name)
    end

    desc 'events [DEPLOYMENT_ID]', 'events'
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
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?(options)

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(file_path, project_slug)
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
        handle_succeed_create_response(project_slug, response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_events_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

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

    def handle_succeed_create_response(project_slug, response)
      deployment = response[:body][:deployment]
      deployment_id = deployment[:id]
      params = { id: deployment_id }

      response = deploy_containers(ConfigFile.read_option(:server), project_slug, deployment_id, params)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Preview created with name deployment-#{deployment_id}")
        print_deployment_progress(deployment, project_slug)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def print_deployment_progress(deployment, project_slug)
      deployment_id = deployment[:id]

      @spinner = TTY::Spinner.new('[:spinner] Creating containers...', format: :dots)
      @spinner.auto_spin

      activity_items = []

      loop do
        response = get_activity_items(ConfigFile.read_option(:server), project_slug, deployment_id)
        handle_activity_items_response(response)
        return unless @spinner.spinning?

        activity_items = response[:body][:activity_items]
        break if !activity_items.empty? && activity_items.count == deployment[:containers].count

        sleep(5)
      end

      @spinner.success

      Uffizzi.ui.say('Done')

      @spinner = TTY::Spinner::Multi.new('[:spinner] Deploying preview...', format: :dots, style: {
                                           middle: '  ',
                                           bottom: '  ',
                                         })

      containers_spinners = create_containers_spinners(activity_items)

      wait_containers_deploying(project_slug, deployment_id, containers_spinners)

      if options[:output].nil?
        Uffizzi.ui.say('Done')
        preview_url = "https://#{deployment[:preview_url]}"
        Uffizzi.ui.say(preview_url) if @spinner.success?
      else
        output_data = build_output_data(deployment)
        Uffizzi.ui.output(output_data)
      end
    end

    def wait_containers_deploying(project_slug, deployment_id, containers_spinners)
      loop do
        response = get_activity_items(ConfigFile.read_option(:server), project_slug, deployment_id)
        handle_activity_items_response(response)
        return if @spinner.done?

        activity_items = response[:body][:activity_items]
        check_activity_items_state(activity_items, containers_spinners)
        break if activity_items.all? { |activity_item| activity_item[:state] == 'deployed' || activity_item[:state] == 'failed' }

        sleep(5)
      end
    end

    def create_containers_spinners(activity_items)
      activity_items.map do |activity_item|
        container_spinner = @spinner.register("[:spinner] #{activity_item[:name]}")
        container_spinner.auto_spin
        {
          name: activity_item[:name],
          spinner: container_spinner,
        }
      end
    end

    def check_activity_items_state(activity_items, containers_spinners)
      finished_activity_items = activity_items.filter do |activity_item|
        activity_item[:state] == 'deployed' || activity_item[:state] == 'failed'
      end
      finished_activity_items.each do |activity_item|
        container_spinner = containers_spinners.detect { |spinner| spinner[:name] == activity_item[:name] }
        spinner = container_spinner[:spinner]
        case activity_item[:state]
        when 'deployed'
          spinner.success
        when 'failed'
          spinner.error
        end
      end
    end

    def handle_delete_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      response = delete_deployment(ConfigFile.read_option(:server), project_slug, deployment_id)

      if ResponseHelper.no_content?(response)
        handle_succeed_delete_response(deployment_id)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_describe_command(deployment_name, project_slug)
      deployment_id = PreviewService.read_deployment_id(deployment_name)

      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") if deployment_id.nil?

      response = describe_deployment(ConfigFile.read_option(:server), project_slug, deployment_id)

      if ResponseHelper.ok?(response)
        handle_succeed_describe_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_activity_items_response(response)
      unless ResponseHelper.ok?(response)
        @spinner.error
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_list_response(response)
      deployments = response[:body][:deployments] || []
      return Uffizzi.ui.say('The project has no active deployments') if deployments.empty?

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

    def build_output_data(output_data)
      {
        id: "deployment-#{output_data[:id]}",
        url: "https://#{output_data[:preview_url]}",
      }
    end
  end
end
