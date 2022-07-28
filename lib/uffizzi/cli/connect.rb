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
    method_option :update_credential_if_exists, type: :boolean, default: false
    def docker_hub
      type = Uffizzi.configuration.credential_types[:dockerhub]
      credential_exists = credential_exists?(type)
      handle_existing_credential_options('docker-hub') if credential_exists

      username = ENV['DOCKERHUB_USERNAME'] || Uffizzi.ui.ask('Username:')
      password = ENV['DOCKERHUB_PASSWORD'] || Uffizzi.ui.ask('Password:', echo: false)

      params = {
        username: username,
        password: password,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credential(server, params, create: !credential_exists)

      if successful?(response)
        print_success_message('Docker Hub')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'acr', 'Connect to Azure Container Registry (azurecr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credential_if_exists, type: :boolean, default: false
    def acr
      type = Uffizzi.configuration.credential_types[:azure]
      credential_exists = credential_exists?(type)
      handle_existing_credential_options('acr') if credential_exists

      registry_url = ENV['ACR_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain:')
      username = ENV['ACR_USERNAME'] || Uffizzi.ui.ask('Docker ID:')
      password = ENV['ACR_PASSWORD'] || Uffizzi.ui.ask('Password/Access Token:', echo: false)

      params = {
        username: username,
        password: password,
        registry_url: prepare_registry_url(registry_url),
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credential(server, params, create: !credential_exists)

      if successful?(response)
        print_success_message('ACR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'ecr', 'Connect to Amazon Elastic Container Registry'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credential_if_exists, type: :boolean, default: false
    def ecr
      type = Uffizzi.configuration.credential_types[:amazon]
      credential_exists = credential_exists?(type)
      handle_existing_credential_options('ecr') if credential_exists

      registry_url = ENV['AWS_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain:')
      access_key = ENV['AWS_ACCESS_KEY_ID'] || Uffizzi.ui.ask('Access key ID:')
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || Uffizzi.ui.ask('Secret access key:', echo: false)

      params = {
        username: access_key,
        password: secret_access_key,
        registry_url: prepare_registry_url(registry_url),
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credential(server, params, create: !credential_exists)

      if successful?(response)
        print_success_message('ECR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'gcr', 'Connect to Google Container Registry (gcr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credential_if_exists, type: :boolean, default: false
    def gcr(credential_file_path = nil)
      type = Uffizzi.configuration.credential_types[:google]
      credential_exists = credential_exists?(type)
      handle_existing_credential_options('gcr') if credential_exists

      credential_content = google_service_account_content(credential_file_path)

      params = {
        password: credential_content,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credential(server, params, create: !credential_exists)

      if successful?(response)
        print_success_message('GCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'ghcr', 'Connect to GitHub Container Registry (ghcr.io)'
    method_option :skip_raise_existence_error, type: :boolean, default: false,
                                               desc: 'Skip raising an error within check the credential'
    method_option :update_credential_if_exists, type: :boolean, default: false
    method_option :username, type: :string, aliases: :u
    method_option :token, type: :string, aliases: :t
    def ghcr
      type = Uffizzi.configuration.credential_types[:github_registry]
      credential_exists = credential_exists?(type)
      handle_existing_credential_options('ghcr') if credential_exists

      username = options[:username] || ENV['GITHUB_USERNAME'] || Uffizzi.ui.ask('Github Username:')
      password = options[:token] || ENV['GITHUB_ACCESS_TOKEN'] || Uffizzi.ui.ask('Access Token:', echo: false)

      params = {
        username: username,
        password: password,
        type: type,
      }

      server = ConfigFile.read_option(:server)
      response = create_or_update_credential(server, params, create: !credential_exists)

      if successful?(response)
        print_success_message('GHCR')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    map 'list-credentials' => 'list_credentials'
    map 'docker-hub' => 'docker_hub'

    private

    def successful?(response)
      ResponseHelper.created?(response) || ResponseHelper.ok?(response)
    end

    def prepare_registry_url(registry_url)
      return registry_url if registry_url.match?(/^(?:http(s)?:\/\/)/)

      "https://#{registry_url}"
    end

    def print_success_message(credential_type_slug)
      Uffizzi.ui.say("Successfully connected to #{credential_type_slug}.")
    end

    def credential_exists?(type)
      server = ConfigFile.read_option(:server)
      response = check_credential(server, type)
      !ResponseHelper.ok?(response)
    end

    def handle_existing_credential_options(credential_type_slug)
      if options.update_credential_if_exists?
        Uffizzi.ui.say('Updating existing credential.')
        return
      end

      if options.skip_raise_existence_error?
        Uffizzi.ui.say("Credential of type #{credential_type_slug} already exists for this account.")
        exit(true)
      else
        message = "Credential of type #{credential_type_slug} already exists for this account.\n" \
        "To remove them, run uffizzi disconnect #{credential_type_slug}."
        raise Uffizzi::Error.new(message)
      end
    end

    def create_or_update_credential(server, params, create: true)
      create ? create_credential(server, params) : update_credential(server, params, params[:type])
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

      raise Uffizzi::Error.new("Path to a google service account key file wasn't specified.") if credential_file_path.nil?

      begin
        credential_content = File.read(credential_file_path)
      rescue Errno::ENOENT => e
        raise Uffizzi::Error.new(e.message)
      end

      credential_content
    end
  end
end
