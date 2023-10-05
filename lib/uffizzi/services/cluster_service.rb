# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class ClusterService
  CLUSTER_STATE_DEPLOYING_NAMESPACE = 'deploying_namespace'
  CLUSTER_STATE_DEPLOYING = 'deploying'
  CLUSTER_STATE_DEPLOYED = 'deployed'
  CLUSTER_STATE_SCALING_UP = 'scaling_up'
  CLUSTER_FAILED_SCALING_UP = 'failed_scaling_up'
  CLUSTER_STATE_FAILED_DEPLOY_NAMESPACE = 'failed_deploy_namespace'
  CLUSTER_STATE_FAILED = 'failed'
  CLUSTER_NAME_MAX_LENGTH = 15
  MANUAL_CREATION_SOURCE = 'manual'

  class << self
    include ApiClient

    def deployed?(cluster_state)
      cluster_state == CLUSTER_STATE_DEPLOYED
    end

    def deploying?(cluster_state)
      [CLUSTER_STATE_DEPLOYING_NAMESPACE, CLUSTER_STATE_DEPLOYING].include?(cluster_state)
    end

    def failed?(cluster_state)
      [CLUSTER_STATE_FAILED_DEPLOY_NAMESPACE, CLUSTER_STATE_FAILED].include?(cluster_state)
    end

    def scaling_up?(cluster_state)
      cluster_state === CLUSTER_STATE_SCALING_UP
    end

    def failed_scaling_up?(cluster_state)
      cluster_state === CLUSTER_FAILED_SCALING_UP
    end

    def wait_cluster_deploy(project_slug, cluster_name, oidc_token)
      loop do
        params = {
          cluster_name: cluster_name,
          oidc_token: oidc_token,
        }
        response = get_cluster(Uffizzi::ConfigFile.read_option(:server), project_slug, params)
        return Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)

        cluster_data = response.dig(:body, :cluster)

        return cluster_data unless deploying?(cluster_data[:state])

        sleep(5)
      end
    end

    def wait_cluster_scale_up(project_slug, cluster_name)
      loop do
        params = {
          cluster_name: cluster_name,
        }
        response = get_cluster(Uffizzi::ConfigFile.read_option(:server), project_slug, params)
        return Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)

        cluster_data = response.dig(:body, :cluster)

        return cluster_data unless scaling_up?(cluster_data[:state])

        sleep(5)
      end
    end

    def generate_name
      name = Faker::Internet.domain_word[0..CLUSTER_NAME_MAX_LENGTH]

      return name if valid_name?(name)

      generate_name
    end

    def valid_name?(name)
      return false if name.nil?

      regex = /\A[a-zA-Z0-9-]*\z/
      regex.match?(name)
    end
  end
end
