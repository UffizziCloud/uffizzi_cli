# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'

class ClusterCommonService
  class << self
    def save_previous_current_context(kubeconfig_path, current_context)
      return if kubeconfig_path.nil? || Uffizzi::ConfigHelper.previous_current_context_by_path(kubeconfig_path).present?

      previous_current_contexts = Uffizzi::ConfigHelper.set_previous_current_context_by_path(kubeconfig_path, current_context)
      Uffizzi::ConfigFile.write_option(:previous_current_contexts, previous_current_contexts)
    end

    def update_clusters_config(id, params)
      clusters_config = Uffizzi::ConfigHelper.update_clusters_config_by_id(id, params)
      Uffizzi::ConfigFile.write_option(:clusters, clusters_config)
    end

    def parse_kubeconfig(kubeconfig)
      return if kubeconfig.nil?

      Psych.safe_load(Base64.decode64(kubeconfig))
    end
  end
end
