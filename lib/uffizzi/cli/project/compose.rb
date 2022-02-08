# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/compose_file_service'
require 'thor'

module Uffizzi
  class CLI::Project::Compose < Thor
    desc 'add', 'add'
    def add
      Compose.new(options, 'add').run
    end

    desc 'remove', 'remove'
    def remove
      Compose.new(options, 'remove').run
    end

    desc 'describe', 'describe'
    def describe
      Compose.new(options, 'describe').run
    end

    desc 'validate', 'validate'
    def validate
      Compose.new(options, 'validate').run
    end

    class Compose
      include ApiClient

      def initialize(options, command)
        @options = options
        @command = command
      end

      def run
        return if !Uffizzi::AuthHelper.signed_in? || !Uffizzi::AuthHelper.project_set?

        file_path = @options[:file]
        case @command
        when 'add'
          handle_add_command(file_path)
        when 'remove'
          handle_remove_command
        when 'describe'
          handle_describe_command
        when 'validate'
          handle_validate_command(file_path)
        end
      end

      private

      def handle_add_command(file_path)
        if file_path.nil?
          Uffizzi.ui.say('No file provided')
          return
        end
        hostname = ConfigFile.read_option(:hostname)
        project_slug = ConfigFile.read_option(:project)
        params = prepare_params(file_path)
        response = add_compose_file(hostname, params, project_slug)

        if response[:code] == Net::HTTPCreated
          Uffizzi.ui.say('compose file created')
        else
          handle_failed_response(response)
        end
      end

      def handle_remove_command
        hostname = ConfigFile.read_option(:hostname)
        project_slug = ConfigFile.read_option(:project)
        response = remove_compose_file(hostname, {}, project_slug)
        if response[:code] == Net::HTTPNoContent
          Uffizzi.ui.say('compose file deleted')
        else
          handle_failed_response(response)
        end
      end

      def handle_describe_command
        hostname = ConfigFile.read_option(:hostname)
        project_slug = ConfigFile.read_option(:project)
        response = describe_compose_file(hostname, {}, project_slug)

        if response[:code] == Net::HTTPOK
          compose_file_content = response[:body][:compose_file][:content]
          Uffizzi.ui.say(Base64.decode64(compose_file_content))
        else
          handle_failed_response(response)
        end
      end

      def handle_validate_command(file_path)
        if file_path.nil?
          Uffizzi.ui.say('No file provided')
          return
        end
        hostname = ConfigFile.read_option(:hostname)
        project_slug = ConfigFile.read_option(:project)
        params = prepare_params(file_path)
        response = validate_compose_file(hostname, params, project_slug)

        if response[:code] == Net::HTTPOK
          Uffizzi.ui.say('compose file is valid')
        else
          handle_failed_response(response)
        end
      end

      def handle_failed_response(response)
        print_errors(response[:body][:errors])
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
    end
  end
end
