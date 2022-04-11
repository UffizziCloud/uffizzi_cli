# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/compose_file_service'
require 'uffizzi/services/env_variables_service'

module Uffizzi
  class Cli::Project::Compose < Thor
    include ApiClient

    desc 'set [OPTIONS]', 'set'
    def set
      run('set')
    end

    desc 'unset', 'unset'
    def unset
      run('unset')
    end

    desc 'describe', 'describe'
    def describe
      run('describe')
    end

    private

    def run(command)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?(options)

      @project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      @server = ConfigFile.read_option(:server)
      file_path = options[:file]
      case command
      when 'set'
        handle_set_command(file_path)
      when 'unset'
        handle_unset_command
      when 'describe'
        handle_describe_command
      end
    end

    def handle_set_command(file_path)
      return Uffizzi.ui.say('No file provided') if file_path.nil?

      params = prepare_params(file_path)
      response = set_compose_file(@server, params, @project_slug)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('compose file created')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_unset_command
      server = ConfigFile.read_option(:server)
      project_slug = ConfigFile.read_option(:project)
      response = unset_compose_file(server, project_slug)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('compose file deleted')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_describe_command
      server = ConfigFile.read_option(:server)
      project_slug = ConfigFile.read_option(:project)
      response = describe_compose_file(server, project_slug)
      compose_file = response[:body][:compose_file]

      if ResponseHelper.ok?(response)
        if compose_file_valid?(compose_file)
          Uffizzi.ui.say(Base64.decode64(compose_file[:content]))
        else
          ResponseHelper.handle_invalid_compose_response(response)
        end
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def compose_file_valid?(compose_file)
      compose_file[:state] == 'valid_file'
    end

    def prepare_params(file_path)
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
  end
end
