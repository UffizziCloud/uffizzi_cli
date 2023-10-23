# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/kubeconfig_service'

class ClusterUpdateKubeconfigService
  class << self
    def say_error_update_kubeconfig(cluster_data)
      if ClusterService.failed?(cluster_data[:state])
        Uffizzi.ui.say_error_and_exit('Kubeconfig is empty because cluster failed to be created.')
      end

      if ClusterService.deploying?(cluster_data[:state])
        Uffizzi.ui.say_error_and_exit('Kubeconfig is empty because cluster is deploying.')
      end

      if ClusterService.deployed?(cluster_data[:state])
        raise Error.new("Cluster with data: #{cluster_data.to_json} is deployed but kubeconfig does not exist.")
      end
    end
  end
end
