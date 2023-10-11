# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/compose_file_service'
require 'uffizzi/services/env_variables_service'

module Uffizzi
  class Cli::Project::Compose < Thor
    include ApiClient

    desc 'set [OPTIONS]', 'Set the configuration of a project with a compose file'
    def set
      run('set')
    end

    desc 'unset', 'Unset the compose file for a project'
    def unset
      run('unset')
    end

    desc 'describe', 'Display details of a compose file'
    def describe
      run('describe')
    end

    private

    def run(command)
      Uffizzi::AuthHelper.check_login(options[:project])

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
      file_path = options[:file]
      case command
      when 'set'
        handle_set_command(project_slug, file_path)
      when 'unset'
        handle_unset_command(project_slug)
      when 'describe'
        handle_describe_command(project_slug)
      end
    end

    def handle_set_command(project_slug, file_path)
      return Uffizzi.ui.say('No file provided') if file_path.nil?

      params = prepare_params(file_path)
      response = set_compose_file(ConfigFile.read_option(:server), params, project_slug)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('compose file created')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_unset_command(project_slug)
      server = ConfigFile.read_option(:server)
      response = unset_compose_file(server, project_slug)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('compose file deleted')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_describe_command(project_slug)
      server = ConfigFile.read_option(:server)
      response = describe_compose_file(server, project_slug)
      compose_file = response[:body][:compose_file]

      if ResponseHelper.ok?(response)
        if compose_file_valid?(compose_file)
          Uffizzi.ui.say(Base64.decode64(compose_file[:content]))
        else
          ResponseHelper.handle_invalid_compose_response(response)
        end
      elsif ResponseHelper.not_found?(response)
        Uffizzi.ui.say('The project does not have a compose file set.')
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
