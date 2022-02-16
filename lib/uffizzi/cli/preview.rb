# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'

module Uffizzi
  class CLI::Preview < Thor
    include ApiClient

    class << self
      def help(_shell, _subcommand = false)
        return Cli::Common.show_manual(:preview)
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

      case command
      when 'list'
        handle_list_command(options)
      when 'create'
        handle_create_command(options, file_path)
      when 'delete'
        handle_delete_command(options, deployment)
      when 'describe'
        handle_describe_command(options, deployment)
      end
    end

    def handle_list_command(options)
      hostname = ConfigFile.read_option(:hostname)
      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      response = fetch_deployments(hostname, project_slug)

      if response[:code] == Net::HTTPOK
        handle_succeed_list_response(response)
      else
        handle_failed_response(response)
      end
    end

    def handle_create_command(options, file_path)
      hostname = ConfigFile.read_option(:hostname)
      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      params = file_path.nil? ? {} : prepare_params(file_path)
      response = create_deployment(hostname, project_slug, params)

      if response[:code] == Net::HTTPCreated
        handle_succeed_create_response(response)
      else
        handle_failed_response(response)
      end
    end

    def handle_delete_command(options, deployment)
      if !deployment_name_valid?(deployment)
        Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format")
        return
      end
      hostname = ConfigFile.read_option(:hostname)
      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      deployment_id = deployment.split('-').last
      params = { id: deployment_id }

      response = delete_deployment(hostname, project_slug, deployment_id, params)

      if response[:code] == Net::HTTPNoContent
        handle_succeed_delete_response(response, deployment_id)
      else
        handle_failed_response(response)
      end
    end

    def handle_describe_command(options, deployment)
      if !deployment_name_valid?(deployment)
        Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format")
        return
      end
      hostname = ConfigFile.read_option(:hostname)
      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      deployment_id = deployment.split('-').last
      params = { id: deployment_id }

      response = describe_deployment(hostname, project_slug, deployment_id, params)

      if response[:code] == Net::HTTPOK
        handle_succeed_describe_response(response)
      else
        handle_failed_response(response)
      end
    end

    def handle_succeed_list_response(response)
      deployments = response[:body][:deployments]
      deployments.each do |deployment|
        Uffizzi.ui.say("deployment-#{deployment[:id]}")
      end
    end

    def handle_succeed_create_response(response)
      deployment = response[:body][:deployment]
      Uffizzi.ui.say("Preview created with name deployment-#{deployment[:id]}")
    end

    def handle_succeed_delete_response(response, deployment_id)
      Uffizzi.ui.say("Preview deployment-#{deployment_id} deleted")
    end

    def handle_succeed_describe_response(response)
      deployment = response[:body][:deployment]
      Uffizzi.ui.say(deployment)
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

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end

    def deployment_name_valid?(deployment)
      !(deployment =~ /^deployment-[0-9]+$/).nil?
    end
  end
end
