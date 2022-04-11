# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class Cli::Connect
    include ApiClient

    def run(connection_name, credential_file_path)
      case connection_name
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
      type = Uffizzi.configuration.credential_types[:dockerhub]
      check_credential_existance(type, 'docker-hub')

      username = Uffizzi.ui.ask('Username: ')
      password = Uffizzi.ui.ask('Password: ', echo: false)

      params = {
        username: username,
        password: password,
        type: Uffizzi.configuration.credential_types[:dockerhub],
      }

      server = ConfigFile.read_option(:server)
      response = create_credential(server, params)

      if ResponseHelper.created?(response)
        print_success_message('DockerHub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_azure
      type = Uffizzi.configuration.credential_types[:azure]
      check_credential_existance(type, 'acr')

      registry_url = prepare_registry_url(Uffizzi.ui.ask('Registry Domain: '))
      username = Uffizzi.ui.ask('Docker ID: ')
      password = Uffizzi.ui.ask('Password/Access Token: ', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_credential(server, params)

      if ResponseHelper.created?(response)
        print_success_message('ACR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_amazon
      type = Uffizzi.configuration.credential_types[:amazon]
      check_credential_existance(type, 'ecr')

      registry_url = prepare_registry_url(Uffizzi.ui.ask('Registry Domain: '))
      username = Uffizzi.ui.ask('Access key ID: ')
      password = Uffizzi.ui.ask('Secret access key: ', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: registry_url,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_credential(server, params)

      if ResponseHelper.created?(response)
        print_success_message('ECR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_google(credential_file_path)
      type = Uffizzi.configuration.credential_types[:google]
      check_credential_existance(type, 'gcr')

      return Uffizzi.ui.say('Path to google service account key file wasn\'t specified.') if credential_file_path.nil?

      begin
        credential_content = File.read(credential_file_path)
      rescue Errno::ENOENT => e
        return Uffizzi.ui.say(e)
      end

      params = {
        password: credential_content,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_credential(server, params)

      if ResponseHelper.created?(response)
        print_success_message('GCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_github_container_registry
      type = Uffizzi.configuration.credential_types[:github_container_registry]
      check_credential_existance(type, 'gchr')

      username = Uffizzi.ui.ask('Github Username: ')
      password = Uffizzi.ui.ask('Access Token: ', echo: false)

      params = {
        username: username,
        password: password,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_credential(server, params)

      if ResponseHelper.created?(response)
        print_success_message('GHCR')
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

    def check_credential_existance(type, connection_name)
      server = ConfigFile.read_option(:server)
      response = check_credential(server, type)
      return if ResponseHelper.ok?(response)

      message = "Credentials of type #{connection_name} already exist for this account.
      To remove them, run $ uffizzi disconnect #{connection_name}"
      raise Uffizzi::Error.new(message)
    end
  end
end
