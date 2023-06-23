# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'
require 'psych'

class KubeconfigService
  class << self
    include ApiClient

    def merge(target_kubeconfig, source_kubeconfig)
      return source_kubeconfig if target_kubeconfig.nil?

      new_cluster_name = get_current_cluster_name(source_kubeconfig)

      if cluster_exists_in_kubeconfig?(target_kubeconfig, new_cluster_name)
        replace(target_kubeconfig, source_kubeconfig, new_cluster_name)
      else
        add(target_kubeconfig, source_kubeconfig)
      end
    end

    def save_to_filepath(filepath, kubeconfig)
      target_kubeconfig = File.exist?(filepath) ? Psych.safe_load(File.read(filepath)) : nil
      new_kubeconfig = merge(target_kubeconfig, kubeconfig)

      File.write(filepath, new_kubeconfig.to_yaml)
    end

    private

    def cluster_exists_in_kubeconfig?(kubeconfig, cluster_name)
      !kubeconfig['clusters'].detect { |c| c['name'] == cluster_name }.nil?
    end

    def add(target_kubeconfig, source_kubeconfig)
      new_kubeconfig = target_kubeconfig.deep_dup
      new_kubeconfig['clusters'] << source_kubeconfig['clusters'][0]
      new_kubeconfig['contexts'] << source_kubeconfig['contexts'][0]
      new_kubeconfig['users'] << source_kubeconfig['users'][0]

      new_kubeconfig
    end

    def replace(target_kubeconfig, source_kubeconfig, cluster_name)
      new_kubeconfig = target_kubeconfig.deep_dup
      new_kubeconfig['clusters'].delete_if { |c| c['name'] == cluster_name }
      target_user = new_kubeconfig['contexts']
        .detect { |c| c.dig('context', 'cluster') == cluster_name }
        .dig('context', 'user')
      new_kubeconfig['contexts'].delete_if { |c| c.dig('context', 'cluster') == cluster_name }
      new_kubeconfig['users'].delete_if { |c| c['name'] == target_user }

      add(new_kubeconfig, source_kubeconfig)
    end

    def get_current_cluster_name(kubeconfig)
      kubeconfig['contexts']
        .detect { |c| c['name'] == kubeconfig['current-context'] }
        .dig('context', 'cluster')
    end
  end
end
