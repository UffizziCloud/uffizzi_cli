# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'
require 'psych'

class KubeconfigService
  DEFAULT_KUBECONFIG_PATH = '~/.kube/config'

  class << self
    include ApiClient

    def merge(target_kubeconfig, source_kubeconfig)
      return source_kubeconfig.deep_dup if target_kubeconfig.nil?

      new_cluster_name = get_current_cluster_name(source_kubeconfig)

      if cluster_exists_in_kubeconfig?(target_kubeconfig, new_cluster_name)
        replace(target_kubeconfig, source_kubeconfig, new_cluster_name)
      else
        add(target_kubeconfig, source_kubeconfig)
      end
    end

    def get_current_context(kubeconfig)
      kubeconfig['current-context']
    end

    def update_current_context(kubeconfig, current_context)
      new_kubeconfig = kubeconfig.deep_dup
      new_kubeconfig['current-context'] = current_context

      new_kubeconfig
    end

    def save_to_filepath(filepath, kubeconfig)
      real_file_path = File.expand_path(filepath)
      target_kubeconfig = File.exist?(real_file_path) ? Psych.safe_load(File.read(real_file_path)) : nil
      new_kubeconfig = block_given? ? yield(target_kubeconfig) : merge(target_kubeconfig, kubeconfig)

      dir_path = File.dirname(real_file_path)
      FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)
      File.write(real_file_path, new_kubeconfig.to_yaml)
    end

    def default_path
      kubeconfig_env_path || DEFAULT_KUBECONFIG_PATH
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

    def kubeconfig_env_path
      file_paths = ENV['KUBECONFIG']
      return if file_paths.blank?

      file_paths.split(':').first
    end
  end
end
