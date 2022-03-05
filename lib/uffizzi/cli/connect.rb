# frozen_string_literal: true

require 'uffizzi'
# require 'io/console'

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

      pp params
    end
  end
end
