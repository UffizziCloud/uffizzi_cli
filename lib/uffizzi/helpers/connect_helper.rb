# frozen_string_literal: true

module Uffizzi
  module ConnectHelper
    class << self
      def get_docker_registry_data(options)
        registry_url = options[:registry] || ENV['DOCKER_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain:')
        username = options[:username] || ENV['DOCKER_REGISTRY_USERNAME'] || Uffizzi.ui.ask('Username:')
        password = options[:password] || ENV['DOCKER_REGISTRY_PASSWORD'] || Uffizzi.ui.ask('Password:', echo: false)

        [registry_url, username, password]
      end

      def get_docker_hub_data(options)
        username = options[:username] || ENV['DOCKERHUB_USERNAME'] || Uffizzi.ui.ask('Username:')
        password = options[:password] || ENV['DOCKERHUB_PASSWORD'] || Uffizzi.ui.ask('Password:', echo: false)

        [username, password]
      end

      def get_acr_data(options)
        registry_url = options[:registry] || ENV['ACR_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain:')
        username = options[:username] || ENV['ACR_USERNAME'] || Uffizzi.ui.ask('Docker ID:')
        password = options[:password] || ENV['ACR_PASSWORD'] || Uffizzi.ui.ask('Password/Access Token:', echo: false)

        [registry_url, username, password]
      end

      def get_ecr_data(options)
        registry_url = options[:registry] || ENV['AWS_REGISTRY_URL'] || Uffizzi.ui.ask('Registry Domain:')
        access_key_id = options[:id] || ENV['AWS_ACCESS_KEY_ID'] || Uffizzi.ui.ask('Access key ID:')
        secret_access_key = options[:secret] || ENV['AWS_SECRET_ACCESS_KEY'] || Uffizzi.ui.ask('Secret access key:', echo: false)

        [registry_url, access_key_id, secret_access_key]
      end

      def get_ghcr_data(options)
        username = options[:username] || ENV['GITHUB_USERNAME'] || Uffizzi.ui.ask('Github Username:')
        password = options[:token] || ENV['GITHUB_ACCESS_TOKEN'] || Uffizzi.ui.ask('Access Token:', echo: false)

        [username, password]
      end
    end
  end
end
