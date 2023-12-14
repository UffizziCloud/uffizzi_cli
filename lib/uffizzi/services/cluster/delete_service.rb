# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'
require 'uffizzi/response_helper'
require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/kubeconfig_service'

class ClusterDeleteService
  extend ApiClient

  class << self
    def exclude_kubeconfig(cluster_id, kubeconfig)
      cluster_config = Uffizzi::ConfigHelper.cluster_config_by_id(cluster_id)
      return if cluster_config.nil?

      kubeconfig_path = cluster_config[:kubeconfig_path]
      Uffizzi::ConfigFile.write_option(:clusters, Uffizzi::ConfigHelper.clusters_config_without(cluster_id))

      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        if kubeconfig_by_path.nil?
          msg = "Warning: kubeconfig at path #{kubeconfig_path} does not exist"
          return Uffizzi.ui.say(msg)
        end

        new_kubeconfig = KubeconfigService.exclude(kubeconfig_by_path, kubeconfig)
        new_current_context = find_previous_current_context(new_kubeconfig, kubeconfig_path)
        KubeconfigService.update_current_context(new_kubeconfig, new_current_context)
      end
    end

    def find_previous_current_context(kubeconfig, kubeconfig_path)
      prev_current_context = Uffizzi::ConfigHelper.previous_current_context_by_path(kubeconfig_path)&.fetch(:current_context, nil)

      if KubeconfigService.find_cluster_contexts_by_name(kubeconfig, prev_current_context).present?
        prev_current_context
      end
    end

    def delete(cluster_name, connection_params)
      params = {
        cluster_name: cluster_name,
        oidc_token: connection_params[:oidc_token],
      }
      response = delete_cluster(connection_params[:server], connection_params[:project_slug], params)

      if Uffizzi::ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Cluster #{cluster_name} deleted")
      else
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end
  end
end
