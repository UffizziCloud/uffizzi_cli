# frozen_string_literal: true

module Uffizzi
  module ConfigHelper
    CLUSTER_PARAMS = [:kubeconfig_path, :name].freeze

    class ConfigParamsError < StandardError
      def initialize(unavailable_params, key)
        msg = "These params #{unavailable_params.join(', ')} is not available for #{key}"

        super(msg)
      end
    end

    class << self
      def read_option_from_config(option)
        ConfigFile.option_has_value?(option) ? ConfigFile.read_option(option) : nil
      end

      def account_config(id, name = nil)
        { id: id, name: name }
      end

      def update_clusters_config_by_id(id, params)
        unavailable_params = params.keys - CLUSTER_PARAMS
        raise ConfigParamsError.new(unavailable_params, :cluster) if unavailable_params.present?

        current_cluster = cluster_config_by_id(id) || {}
        new_current_cluster = current_cluster.merge({ id: id }).merge(params)

        clusters_config_without(id) << new_current_cluster
      end

      def clusters_config_without(id)
        clusters.reject { |c| c[:id] == id }
      end

      def cluster_config_by_id(id)
        clusters.detect { |c| c[:id] == id }
      end

      def set_previous_current_context_by_path(path, current_context)
        current_contexts = previous_current_contexts_without(path)
        current_contexts << { current_context: current_context, kubeconfig_path: path }
      end

      def previous_current_contexts_without(path)
        cluster_previous_current_contexts.reject { |c| c[:kubeconfig_path] == path }
      end

      def previous_current_context_by_path(path)
        cluster_previous_current_contexts.detect { |c| c[:kubeconfig_path] == path }
      end

      private

      def clusters
        read_option_from_config(:clusters) || []
      end

      def cluster_previous_current_contexts
        read_option_from_config(:previous_current_contexts) || []
      end
    end
  end
end
