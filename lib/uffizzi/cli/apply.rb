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
      create_compose_file(hostname, params)
    end

    private

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
