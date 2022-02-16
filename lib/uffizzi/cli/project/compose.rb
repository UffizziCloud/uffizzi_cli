# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/compose_file_service'
require 'thor'

module Uffizzi
  class CLI::Project::Compose < Thor
    include ApiClient

    desc 'set', 'set'
    def set
      run(options, 'set')
    end

    desc 'unset', 'unset'
    def unset
      run(options, 'unset')
    end

    desc 'describe', 'describe'
    def describe
      run(options, 'describe')
    end

    private

    def run(options, command)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?

      file_path = options[:file]
      case command
      when 'set'
        handle_set_command(file_path)
      when 'unset'
        handle_unset_command
      when 'describe'
        handle_describe_command
      when 'validate'
        handle_validate_command(file_path)
      end
    end

    def handle_set_command(file_path)
      return Uffizzi.ui.say('No file provided') if file_path.nil?

      hostname = ConfigFile.read_option(:hostname)
      project_slug = ConfigFile.read_option(:project)
      params = prepare_params(file_path)
      response = set_compose_file(hostname, params, project_slug)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('compose file created')
      else
        handle_failed_response(response)
      end
    end

    def handle_unset_command
      hostname = ConfigFile.read_option(:hostname)
      project_slug = ConfigFile.read_option(:project)
      response = unset_compose_file(hostname, {}, project_slug)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('compose file deleted')
      else
        handle_failed_response(response)
      end
    end

    def handle_describe_command
      hostname = ConfigFile.read_option(:hostname)
      project_slug = ConfigFile.read_option(:project)
      response = describe_compose_file(hostname, {}, project_slug)
      compose_file = response[:body][:compose_file]

      if ResponseHelper.ok?(response)
        if compose_file_valid?(compose_file)
          Uffizzi.ui.say(Base64.decode64(compose_file[:content]))
        else
          print_errors(compose_file[:payload][:errors])
        end
      else
        handle_failed_response(response)
      end
    end

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end

    def compose_file_valid?(compose_file)
      compose_file[:state] == "valid_file"
    end

    def prepare_params(file_path)
      begin
        compose_file_data = File.read(file_path)
      rescue Errno::ENOENT => e
        return Uffizzi.ui.say(e)
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
