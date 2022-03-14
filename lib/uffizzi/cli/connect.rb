# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class CLI::Connect
    include ApiClient

    def run(credential_type)
      case credential_type
      when 'docker-hub'
        handle_docker_hub
      else
        Uffizzi.ui.error('Unsupported credetial type.')
      end
    end

    private

    def handle_docker_hub
      IO::console.write('Enter username: ')
      username = IO::console.gets

      password = IO::console.getpass('Enter password: ')

      params = {
        username: username,
        password: password,
        type: Uffizzi.configuration.credential_types[:dockerhub],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        Uffizzi.ui.success('Successfully connected to DockerHub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end
  end
end
