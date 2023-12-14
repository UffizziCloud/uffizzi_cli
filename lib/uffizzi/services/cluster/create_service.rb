# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/cluster/common_service'
require 'uffizzi/services/kubeconfig_service'

class ClusterCreateService
  class << self
    def save_kubeconfig(kubeconfig, kubeconfig_path, update_current_context:)
      kubeconfig_path = kubeconfig_path.nil? ? KubeconfigService.default_path : kubeconfig_path

      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, kubeconfig)

        if update_current_context
          new_current_context = KubeconfigService.get_current_context(kubeconfig)
          new_kubeconfig = KubeconfigService.update_current_context(merged_kubeconfig, new_current_context)

          next new_kubeconfig if kubeconfig_by_path.nil?

          previous_current_context = KubeconfigService.get_current_context(kubeconfig_by_path)
          ClusterCommonService.save_previous_current_context(kubeconfig_path, previous_current_context)
          new_kubeconfig
        else
          merged_kubeconfig
        end
      end
    end
  end
end
