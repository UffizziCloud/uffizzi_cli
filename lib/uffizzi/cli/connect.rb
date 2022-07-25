# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class Cli::Connect < Thor
    include ApiClient

    desc 'list-credentials', 'List existing credentials for an account'
    def list_credentials
      server = ConfigFile.read_option(:server)
      response = fetch_credentials(server)
      if ResponseHelper.ok?(response)
        handle_list_credentials_success(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'docker-hub', 'Connect to Docker Hub (hub.docker.com)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credentials_if_exist, type: :boolean, default: false
    def docker_hub
      type = Uffizzi.configuration.credential_types[:dockerhub]
      exist = check_credential_existence(type, 'docker-hub')

      username = ENV['DOCKERHUB_USERNAME'] || Uffizzi.ui.ask('Username: ')
      password = ENV['DOCKERHUB_PASSWORD'] || Uffizzi.ui.ask('Password: ', echo: false)

      params = {
        username: username,
        password: password,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credentials(server, params, create: !exist)

      if ResponseHelper.created?(response) || ResponseHelper.ok?(response)
        print_success_message('DockerHub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'acr', 'Connect to Azure Container Registry (azurecr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credentials_if_exist, type: :boolean, default: false
    def acr
      type = Uffizzi.configuration.credential_types[:azure]
      exist = check_credential_existence(type, 'acr')

      registry_url = ENV['ACR_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain: ')
      username = ENV['ACR_USERNAME'] || Uffizzi.ui.ask('Docker ID: ')
      password = ENV['ACR_PASSWORD'] || Uffizzi.ui.ask('Password/Access Token: ', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: prepare_registry_url(registry_url),
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credentials(server, params, create: !exist)

      if ResponseHelper.created?(response) || ResponseHelper.ok?(response)
        print_success_message('ACR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'ecr', 'Connect to Amazon Elastic Container Registry'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credentials_if_exist, type: :boolean, default: false
    def ecr
      type = Uffizzi.configuration.credential_types[:amazon]
      exist = check_credential_existence(type, 'ecr')

      registry_url = ENV['AWS_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain: ')
      access_key = ENV['AWS_ACCESS_KEY_ID'] || Uffizzi.ui.ask('Access key ID: ')
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || Uffizzi.ui.ask('Secret access key: ', echo: false)

      params = {
        username: access_key,
        password: secret_access_key,
        registry_url: prepare_registry_url(registry_url),
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credentials(server, params, create: !exist)

      if ResponseHelper.created?(response) || ResponseHelper.ok?(response)
        print_success_message('ECR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'gcr', 'Connect to Google Container Registry (gcr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credentials_if_exist, type: :boolean, default: false
    def gcr(credential_file_path = nil)
      type = Uffizzi.configuration.credential_types[:google]
      exist = check_credential_existence(type, 'gcr')

      credential_content = google_service_account_content(credential_file_path)

      params = {
        password: credential_content,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credentials(server, params, create: !exist)

      if ResponseHelper.created?(response) || ResponseHelper.ok?(response)
        print_success_message('GCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'ghcr', 'Connect to GitHub Container Registry (ghcr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credentials_if_exist, type: :boolean, default: false
    method_option :username, type: :string, aliases: :u
    method_option :token, type: :string, aliases: :t
    def ghcr
      type = Uffizzi.configuration.credential_types[:github_registry]
      exist = check_credential_existence(type, 'ghcr')

      username = options[:username] || ENV['GITHUB_USERNAME'] || Uffizzi.ui.ask('Github Username:')
      password = options[:token] || ENV['GITHUB_ACCESS_TOKEN'] || Uffizzi.ui.ask('Access Token:', echo: false)

      params = {
        username: username,
        password: password,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credentials(server, params, create: !exist)

      if ResponseHelper.created?(response) || ResponseHelper.ok?(response)
        print_success_message('GHCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    map 'list-credentials' => 'list_credentials'
    map 'docker-hub' => 'docker_hub'

    private

    def prepare_registry_url(registry_url)
      return registry_url if registry_url.match?(/^(?:http(s)?:\/\/)/)

      "https://#{registry_url}"
    end

    def print_success_message(connection_name)
      Uffizzi.ui.say("Successfully connected to #{connection_name}")
    end

    def check_credential_existence(type, connection_name)
      server = ConfigFile.read_option(:server)
      response = check_credential(server, type)
      return false if ResponseHelper.ok?(response)

      if options.update_credentials_if_exist?
        Uffizzi.ui.say("Updating existing credentials")
        true
      elsif options.skip_raise_existence_error?
        Uffizzi.ui.say("Credentials of type #{connection_name} already exist for this account.")
        exit(true)
      else
        message = "Credentials of type #{connection_name} already exist for this account.\n" \
        "To remove them, run uffizzi disconnect #{connection_name}."
        raise Uffizzi::Error.new(message)
      end
    end

    def create_or_update_credentials(server, params, create: true)
      create ? create_credential(server, params) : update_credentials(server, params)
    end

    def handle_list_credentials_success(response)
      credentials = response[:body][:credentials]
      credentials.each do |credential|
        Uffizzi.ui.say(credential_readable_name(credential))
      end
    end

    def credential_readable_name(credential)
      map = {
        'UffizziCore::Credential::DockerHub' => 'docker-hub',
        'UffizziCore::Credential::Github' => 'github',
        'UffizziCore::Credential::Azure' => 'acr',
        'UffizziCore::Credential::Amazon' => 'ecr',
        'UffizziCore::Credential::GithubContainerRegistry' => 'ghcr',
        'UffizziCore::Credential::Google' => 'gcr',
      }

      map[credential]
    end

    def google_service_account_content(credential_file_path = nil)
      return ENV['GCLOUD_SERVICE_KEY'] if ENV['GCLOUD_SERVICE_KEY']

      return Uffizzi.ui.say('Path to google service account key file wasn\'t specified.') if credential_file_path.nil?

      begin
        credential_content = File.read(credential_file_path)
      rescue Errno::ENOENT => e
        raise Uffizzi::Error.new(e.message)
      end

      credential_content
    end
  end
end
