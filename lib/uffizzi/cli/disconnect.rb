# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class Cli::Disconnect
    include ApiClient

    def run(credential_type)
      connection_type = case credential_type
                        when 'docker-hub'
                          Uffizzi.configuration.credential_types[:dockerhub]
                        when 'docker-registry'
                          Uffizzi.configuration.credential_types[:docker_registry]
                        when 'acr'
                          Uffizzi.configuration.credential_types[:azure]
                        when 'ecr'
                          Uffizzi.configuration.credential_types[:amazon]
                        when 'gcr'
                          Uffizzi.configuration.credential_types[:google]
                        when 'ghcr'
                          Uffizzi.configuration.credential_types[:github_registry]
                        else
                          raise Uffizzi::Error.new('Unsupported credential type.')
      end

      response = delete_credential(ConfigFile.read_option(:server), ConfigFile.read_option(:account, :id), connection_type)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Successfully disconnected from #{connection_name(credential_type)}.")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def connection_name(credential_type)
      {
        'docker-hub' => 'DockerHub',
        'docker-registry' => 'Docker Registry',
        'acr' => 'ACR',
        'ecr' => 'ECR',
        'gcr' => 'GCR',
        'ghcr' => 'GHCR',
      }[credential_type]
    end
  end
end
