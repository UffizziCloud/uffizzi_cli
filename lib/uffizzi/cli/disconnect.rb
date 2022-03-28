# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class CLI::Disconnect
    include ApiClient

    def run(credential_type)
      return Uffizzi.ui.say('Unsupported credential type.') unless credential_type_supported?(credential_type)

      credential_type_name = case credential_type
                             when 'docker-hub'
                               Uffizzi.configuration.credential_types[:dockerhub]
                             when 'acr'
                               Uffizzi.configuration.credential_types[:azure]
                             when 'ecr'
                               Uffizzi.configuration.credential_types[:amazon]
                             when 'gcr'
                               Uffizzi.configuration.credential_types[:google]
      end

      response = delete_credential(ConfigFile.read_option(:hostname), credential_type_name)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Successfully disconnected #{credential_source(credential_type)} credential")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def credential_type_supported?(credential_type)
      ['docker-hub', 'acr', 'ecr', 'gcr'].include?(credential_type)
    end

    def credential_source(credential_type)
      {
        'docker-hub' => 'DockerHub',
        'acr' => 'ACR',
        'ecr' => 'ECR',
        'gcr' => 'GCR',
      }[credential_type]
    end
  end
end