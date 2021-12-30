# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/clients/api/api_client'
require 'uffizzi/services/compose_file_service'

module Uffizzi
  class CLI::Apply
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      hostname = ConfigFile.read_option(:hostname)
      params = prepare_params
      response = create_compose_file(hostname, params)

      if response[:code] == Net::HTTPCreated
        handle_succeed_response(hostname, response)
      else
        handle_failed_response(response)
      end
    end

    private

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end

    def handle_succeed_response(hostname, response)
      template_payload = response[:body][:compose_files].first[:template][:payload]

      params = { deployment: template_payload }

      response = create_deployment(hostname, params)

      if response[:code] == Net::HTTPCreated
        Uffizzi.ui.say('deployment created')
      else
        handle_failed_response(response)
      end
    end

    def prepare_params
      begin
        compose_file_data = File.read(@options[:file])
      rescue Errno::ENOENT => e
        Uffizzi.ui.say(e)
        return
      end

      compose_file_dir = File.dirname(@options[:file])
      dependencies = ComposeFileService.parse(compose_file_data, compose_file_dir)
      project = ConfigFile.read_option(:project)
      compose_file_params = {
        name: File.basename(@options[:file]),
        payload: compose_file_data,
      }

      {
        compose_file: compose_file_params,
        project: project,
        payload: dependencies,
      }
    end
  end
end
