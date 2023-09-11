# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/cluster_service'
require 'uffizzi/services/kubeconfig_service'

class ClusterDisconnectService
  class << self
    def handle(options)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      prev_current_context = Uffizzi::ConfigHelper.previous_current_context_by_path(kubeconfig_path)&.fetch(:current_context, nil)
      kubeconfig = KubeconfigService.read_kubeconfig(kubeconfig_path)

      if kubeconfig.nil?
        return Uffizzi.ui.say("Kubeconfig does not exist by path #{kubeconfig_path}")
      end

      contexts = KubeconfigService.get_cluster_contexts(kubeconfig)
      current_context = KubeconfigService.get_current_context(kubeconfig)

      if contexts.empty?
        return Uffizzi.ui.say("No contexts by kubeconfig path #{kubeconfig_path}")
      end

      if KubeconfigService.find_cluster_contexts_by_name(kubeconfig, prev_current_context).present? &&
          prev_current_context != current_context
        return update_current_context_by_filepath(kubeconfig_path, prev_current_context)
      end

      new_current_context = ask_context(contexts, current_context)
      update_current_context_by_filepath(kubeconfig_path, new_current_context)
      set_previous_current_context_to_config(kubeconfig_path, new_current_context)
    end

    private

    def update_current_context_by_filepath(filepath, current_context)
      KubeconfigService.save_to_filepath(filepath) do |kubeconfig|
        KubeconfigService.update_current_context(kubeconfig, current_context)
      end
    end

    def set_previous_current_context_to_config(kubeconfig_path, current_context)
      previous_current_contexts = Uffizzi::ConfigHelper.set_previous_current_context_by_path(kubeconfig_path, current_context)
      Uffizzi::ConfigFile.write_option(:previous_current_contexts, previous_current_contexts)
    end

    def ask_context(contexts, current_context)
      context_names = contexts
        .map { |c| { name: c['name'], value: c['name'] } }
        .reject { |c| c[:value] == current_context }

      if context_names.empty?
        return Uffizzi.say_error_and_exit('No other contexts')
      end

      question = 'Select origin context to switch on:'
      Uffizzi.prompt.select(question, context_names)
    end
  end
end
