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
      when 'ghcr'
        handle_github_container_registry
      when 'gcr'
        handle_google(credential_file_path)
      else
        Uffizzi.ui.say('Unsupported credential type.')
      end
    end

    private

    def handle_docker_hub
      username = Uffizzi.ui.ask('Username: ')
      password = Uffizzi.ui.ask('Password: ', echo: false)

      params = {
        username: username,
        password: password,
        type: Uffizzi.configuration.credential_types[:dockerhub],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        print_success_message('DockerHub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_azure
      registry_url = prepare_registry_url(Uffizzi.ui.ask('Registry Domain: '))
      username = Uffizzi.ui.ask('Docker ID: ')
      password = Uffizzi.ui.ask('Password/Access Token: ', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: Uffizzi.configuration.credential_types[:azure],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        print_success_message('ACR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_amazon
      registry_url = prepare_registry_url(Uffizzi.ui.ask('Registry Domain: '))
      username = Uffizzi.ui.ask('Access key ID: ')
      password = Uffizzi.ui.ask('Secret access key: ', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: Uffizzi.configuration.credential_types[:amazon],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        print_success_message('ECR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_google(credential_file_path)
      return Uffizzi.ui.say('Path to google service account key file wasn\'t specified.') if credential_file_path.nil?

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
        print_success_message('GCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_github_container_registry
      username = Uffizzi.ui.ask('Github Username: ')
      password = Uffizzi.ui.ask('Access Token: ', echo: false)

      params = {
        username: username,
        password: password,
        type: Uffizzi.configuration.credential_types[:github_container_registry],
      }

      hostname = ConfigFile.read_option(:hostname)
      response = create_credential(hostname, params)

      if ResponseHelper.created?(response)
        print_success_message('GitHub Container Registry')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def prepare_registry_url(registry_url)
      return registry_url if registry_url.match?(/^(?:http(s)?:\/\/)/)

      "https://#{registry_url}"
    end

    def print_success_message(connection_name)
      Uffizzi.ui.say("Successfully connected to #{connection_name}")
    end
  end
end
