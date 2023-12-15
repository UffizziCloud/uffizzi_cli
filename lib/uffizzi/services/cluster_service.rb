# frozen_string_literal: true

require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

class ClusterService
  CLUSTER_STATE_DEPLOYING_NAMESPACE = 'deploying_namespace'
  CLUSTER_STATE_DEPLOYING = 'deploying'
  CLUSTER_STATE_DEPLOYED = 'deployed'
  CLUSTER_STATE_SCALING_DOWN = 'scaling_down'
  CLUSTER_STATE_SCALED_DOWN = 'scaled_down'
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

    def scaling_down?(cluster_state)
      cluster_state === CLUSTER_STATE_SCALING_DOWN
    end

    def scaled_down?(cluster_state)
      cluster_state === CLUSTER_STATE_SCALED_DOWN
    end

    def failed_scaling_up?(cluster_state)
      cluster_state === CLUSTER_FAILED_SCALING_UP
    end

    def wait_cluster_deploy(cluster_name, cluster_api_connection_params)
      loop do
        cluster_data = fetch_cluster_data(cluster_name, **cluster_api_connection_params)
        return cluster_data unless deploying?(cluster_data[:state])

        sleep(5)
      end
    end

    def wait_cluster_scale_up(cluster_name, cluster_api_connection_params)
      loop do
        cluster_data = fetch_cluster_data(cluster_name, **cluster_api_connection_params)
        return cluster_data unless scaling_up?(cluster_data[:state])

        sleep(5)
      end
    end

    def wait_cluster_scale_down(cluster_name, cluster_api_connection_params)
      loop do
        cluster_data = fetch_cluster_data(cluster_name, **cluster_api_connection_params)
        return unless scaling_down?(cluster_data[:state])

        sleep(3)
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

    def fetch_cluster_data(cluster_name, server:, project_slug:, oidc_token:)
      params = {
        cluster_name: cluster_name,
        oidc_token: oidc_token,
      }
      response = get_cluster(server, project_slug, params)

      if Uffizzi::ResponseHelper.ok?(response)
        response.dig(:body, :cluster)
      else
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end

    def sync_cluster_data(cluster_name, server:, project_slug:)
      response = sync_cluster(server, project_slug, cluster_name)

      if Uffizzi::ResponseHelper.ok?(response)
        response.dig(:body, :cluster)
      else
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end

    def build_render_data(cluster_data)
      {
        name: cluster_data[:name],
        status: cluster_data[:state],
        created: Time.strptime(cluster_data[:created_at], '%Y-%m-%dT%H:%M:%S.%N').strftime('%a %b %d %H:%M:%S %Y'),
        host: cluster_data[:host],
      }
    end

    def cluster_status_text_map
      {
        CLUSTER_STATE_SCALING_UP => 'The cluster is scaling up',
        CLUSTER_STATE_SCALED_DOWN => 'The cluster is scaled down',
        CLUSTER_STATE_SCALING_DOWN => 'The cluster is scaling down',
        CLUSTER_FAILED_SCALING_UP => 'The cluster failed scaling up',
        CLUSTER_STATE_FAILED_DEPLOY_NAMESPACE => 'The cluster failed',
        CLUSTER_STATE_FAILED => 'The cluster failed',
      }
    end
  end
end
