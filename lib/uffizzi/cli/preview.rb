# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'

module Uffizzi
  class CLI::Preview < Thor

    desc 'list', 'list'
    def list
      Preview.new(options, 'list', nil, nil).run
    end

    desc 'create', 'create'
    def create(file_path = nil)
      Preview.new(options, 'create', file_path, nil).run
    end

    desc 'delete', 'delete'
    def delete(deployment)
      Preview.new(options, 'delete', nil, deployment).run
    end

    desc 'describe', 'describe'
    def describe(deployment)
      Preview.new(options, 'describe', nil, deployment).run
    end

    class Preview
      include ApiClient

      def initialize(options, command, file_path, deployment)
        @options = options
        @command = command
        @file_path = file_path
        @deployment = deployment
      end

      def run
        return unless Uffizzi::AuthHelper.signed_in?

        case @command
        when 'list'
          handle_list_command
        when 'create'
          handle_create_command
        when 'delete'
          handle_delete_command
        when 'describe'
          handle_describe_command
        end
      end

      private

      def handle_list_command
        hostname = ConfigFile.read_option(:hostname)
        project_slug = @options[:project].nil? ? ConfigFile.read_option(:project) : @options[:project]
        response = fetch_deployments(hostname, project_slug)
  
        if response[:code] == Net::HTTPOK
          handle_succeed_list_response(response)
        else
          handle_failed_response(response)
        end
      end

      def handle_create_command
        hostname = ConfigFile.read_option(:hostname)
        project_slug = @options[:project].nil? ? ConfigFile.read_option(:project) : @options[:project]
        params = @file_path.nil? ? {} : prepare_params(@file_path)
        
        response = create_deployment(hostname, project_slug, params)
  
        if response[:code] == Net::HTTPCreated
          handle_succeed_create_response(response)
        else
          handle_failed_response(response)
        end
      end

      def handle_delete_command
        if !deployment_name_valid?
          Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format")
          return
        end
        hostname = ConfigFile.read_option(:hostname)
        project_slug = @options[:project].nil? ? ConfigFile.read_option(:project) : @options[:project]
        params = { id: deployment_id }

        response = delete_deployment(hostname, project_slug, deployment_id, params)

        if response[:code] == Net::HTTPNoContent
          handle_succeed_delete_response(response)
        else
          handle_failed_response(response)
        end
      end

      def handle_describe_command
        if !deployment_name_valid?
          Uffizzi.ui.say("Preview should be specified in 'deployment-PREVIEW_ID' format")
          return
        end
        hostname = ConfigFile.read_option(:hostname)
        project_slug = @options[:project].nil? ? ConfigFile.read_option(:project) : @options[:project]
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

      def handle_succeed_delete_response(response)
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

      def deployment_name_valid?
        !(@deployment =~ /^deployment-[0-9]+$/).nil?
      end

      def deployment_id
        @deployment.split('-').last
      end
    end
  end
end
