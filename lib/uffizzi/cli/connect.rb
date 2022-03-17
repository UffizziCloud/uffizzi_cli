# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class CLI::Connect
    include ApiClient

    def run(credential_type, credential_file_path)
      case credential_type
      when 'docker-hub'
        handle_docker_hub
      when 'acr'
        handle_azure
      when 'ecr'
        handle_amazon
      when 'gcr'
        handle_google(credential_file_path)
      else
        Uffizzi.ui.say('Unsupported credential type.')
      end
    end

    private

    def handle_docker_hub
      IO::console.write('Username: ')
      username = IO::console.gets.strip

      password = IO::console.getpass('Password: ')

      params = {
        username: username,
        password: password,
        type: Uffizzi.configuration.credential_types[:dockerhub],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('Successfully connected to DockerHub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_azure
      IO::console.write('Registry Domain: ')
      registry_url = IO::console.gets.strip

      IO::console.write('Docker ID: ')
      username = IO::console.gets.strip

      password = IO::console.getpass('Password/Access Token: ')

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: Uffizzi.configuration.credential_types[:azure],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('Successfully connected to ACR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_amazon
      IO::console.write('Registry Domain: ')
      registry_url = IO::console.gets.strip

      IO::console.write('Access key ID: ')
      username = IO::console.gets.strip

      password = IO::console.getpass('Secret access key: ')

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: Uffizzi.configuration.credential_types[:amazon],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('Successfully connected to ECR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_google(credential_file_path)
      begin
        credential_content = File.read(credential_file_path)
      rescue Errno::ENOENT => e
        return Uffizzi.ui.say(e)
      end

      params = {
        password: credential_content,
        type: Uffizzi.configuration.credential_types[:google],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        Uffizzi.ui.say('Successfully connected to GCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end
  end
end
