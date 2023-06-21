# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'
require 'psych'

class KubeconfigService
  class << self
    include ApiClient

    def merge(target_kubeconfig, source_kubeconfig, cluster_name)
      if cluster_exists_in_kubeconfig?(target_kubeconfig, cluster_name)
        replace_by_name(target_kubeconfig, source_kubeconfig, cluster_name)
      else
        add(target_kubeconfig, source_kubeconfig)
      end
    end

    private

    def cluster_exists_in_kubeconfig?(kubeconfig, cluster_name)
      !kubeconfig['clusters'].detect{ |cluster| cluster['name'] == cluster_name }.nil?
    end

    def add(target_kubeconfig, source_kubeconfig)
      new_kubeconfig = target_kubeconfig.clone
      byebug
      new_kubeconfig['clusters'] << source_kubeconfig['clusters'][0]
      new_kubeconfig['contexts'] << source_kubeconfig['contexts'][0]
      new_kubeconfig['users'] << source_kubeconfig['users'][0]

      new_kubeconfig
    end

    def replace_by_name(target_kubeconfig, source_kubeconfig, cluster_name)
      new_kubeconfig = target_kubeconfig.clone
      new_kubeconfig['clusters'].delete_if { |c| c['name'] == cluster_name }
      target_user = new_kubeconfig['contexts']
        .detect { |c| c.dig('context', 'cluster') == cluster_name }
        .dig('context', 'user')
      new_kubeconfig['contexts'].delete_if { |c| c.dig('context', 'cluster') == cluster_name }
      new_kubeconfig['users'].delete_if { |c| c['name'] == target_user }

      add(new_kubeconfig, source_kubeconfig)
    end
  end
end
