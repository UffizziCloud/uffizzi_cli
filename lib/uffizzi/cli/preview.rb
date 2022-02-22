# frozen_string_literal: true

require 'uffizzi'
require 'tty-spinner'
require 'uffizzi/auth_helper'

module Uffizzi
  class CLI::Preview < Thor
    include ApiClient

    @spinner

    class << self
      def help(_shell, _subcommand)
        Cli::Common.show_manual(:preview)
      end
    end

    desc 'list', 'list'
    def list
      return Cli::Common.show_manual(:list) if options[:help]

      run(options, 'list', nil, nil)
    end

    desc 'create', 'create'
    def create(file_path = nil)
      return Cli::Common.show_manual(:create) if options[:help]

      run(options, 'create', file_path, nil)
    end

    desc 'delete', 'delete'
    def delete(deployment)
      return Cli::Common.show_manual(:delete) if options[:help]

      run(options, 'delete', nil, deployment)
    end

    desc 'describe', 'describe'
    def describe(deployment)
      return Cli::Common.show_manual(:describe) if options[:help]

      run(options, 'describe', nil, deployment)
    end

    private

    def run(options, command, file_path, deployment)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(file_path, project_slug)
      when 'delete'
        handle_delete_command(deployment, project_slug)
      when 'describe'
        handle_describe_command(deployment, project_slug)
      end
    end

    def handle_list_command(project_slug)
      hostname = ConfigFile.read_option(:hostname)
      response = fetch_deployments(hostname, project_slug)

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command(file_path, project_slug)
      hostname = ConfigFile.read_option(:hostname)
      params = file_path.nil? ? {} : prepare_params(file_path)
      response = create_deployment(hostname, project_slug, params)

      if ResponseHelper.created?(response)
        handle_succeed_create_response(hostname, project_slug, response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_create_response(hostname, project_slug, response)
      deployment = response[:body][:deployment]
      deployment_id = deployment[:id]
      params = { id: deployment_id }

      response = deploy_containers(hostname, project_slug, deployment_id, params)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Preview created with name deployment-#{deployment_id}")
        print_deployment_progress(hostname, deployment, project_slug)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def print_deployment_progress(hostname, deployment, project_slug)
      deployment_id = deployment[:id]
      params = { deployment_id: deployment_id }

      @spinner = TTY::Spinner.new('[:spinner] Creating containers...', format: :dots)
      @spinner.auto_spin

      activity_items = []

      loop do
        response = get_activity_items(hostname, project_slug, deployment_id, params)
        handle_activity_items_response(response)
        return unless @spinner.spinning?

        activity_items = response[:body][:activity_items]
        break unless activity_items.empty?

        sleep(5)
      end

      @spinner.success

      Uffizzi.ui.say('Done')

      @spinner = TTY::Spinner::Multi.new('[:spinner] Deploying preview...', format: :dots, style: {
                                           middle: '  ',
                                           bottom: '  ',
                                         })

      containers_spinners = create_containers_spinners(activity_items)

      loop do
        response = get_activity_items(hostname, project_slug, deployment_id, params)
        handle_activity_items_response(response)
        return if @spinner.done?

        activity_items = response[:body][:activity_items]
        check_activity_items_state(activity_items, containers_spinners)
        break if activity_items.all? { |activity_item| activity_item[:state] == 'deployed' || activity_item[:state] == 'failed' }

        sleep(5)
      end

      Uffizzi.ui.say('Done')
      preview_url = "http://#{deployment[:preview_url]}"
      Uffizzi.ui.say(preview_url) if @spinner.success?
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

    def handle_delete_command(deployment, project_slug)
      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") unless deployment_name_valid?(deployment)

      hostname = ConfigFile.read_option(:hostname)
      deployment_id = deployment.split('-').last
      params = { id: deployment_id }

      response = delete_deployment(hostname, project_slug, deployment_id, params)

      if ResponseHelper.no_content?(response)
        handle_succeed_delete_response(deployment_id)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_describe_command(deployment, project_slug)
      return Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format") unless deployment_name_valid?(deployment)

      hostname = ConfigFile.read_option(:hostname)
      deployment_id = deployment.split('-').last
      params = { id: deployment_id }

      response = describe_deployment(hostname, project_slug, deployment_id, params)

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
      deployments = response[:body][:deployments]
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
        Uffizzi.ui.say(e)
        return
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

    def deployment_name_valid?(deployment)
      return false unless deployment.start_with?('deployment-')
      return false unless deployment.split('-').size == 2

      deployment_id = deployment.split('-').last
      deployment_id.to_i.to_s == deployment_id
    end
  end
end
