# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/kubeconfig_service'

class ClusterDeleteService
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
        first_context = KubeconfigService.get_first_context(new_kubeconfig)
        new_current_context = first_context.present? ? first_context['name'] : nil
        KubeconfigService.update_current_context(new_kubeconfig, new_current_context)
      end
    end
  end
end
