# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'
require 'psych'

class KubeconfigService
  class InvalidKubeconfigError < StandardError
    def initialize(file_path)
      msg = "Invalid kubeconfig at path '#{file_path}'"

      super(msg)
    end
  end

  KUBECONFIG_GENERAL_KEYS = ['apiVersion', 'clusters', 'contexts', 'current-context', 'kind', 'users'].freeze

  class << self
    include ApiClient

    def merge(target_kubeconfig, source_kubeconfig)
      return source_kubeconfig.deep_dup if target_kubeconfig.nil?

      new_cluster_name = get_current_cluster_name(source_kubeconfig)

      if cluster_exists_in_kubeconfig?(target_kubeconfig, new_cluster_name)
        replace_by_cluster_name(target_kubeconfig, source_kubeconfig, new_cluster_name)
      else
        add(target_kubeconfig, source_kubeconfig)
      end
    end

    def exclude(target_kubeconfig, source_kubeconfig)
      return if target_kubeconfig.nil?

      excludable_cluster_name = get_current_cluster_name(source_kubeconfig)
      exclude_by_cluster_name(target_kubeconfig, excludable_cluster_name)
    end

    def get_current_context(kubeconfig)
      kubeconfig['current-context']
    end

    def get_current_cluster_name(kubeconfig)
      get_cluster_contexts(kubeconfig)
        .detect { |c| c['name'] == get_current_context(kubeconfig) }
        .dig('context', 'cluster')
    end

    def get_cluster_contexts(kubeconfig)
      kubeconfig.fetch('contexts', [])
    end

    def find_cluster_contexts_by_name(kubeconfig, context_name)
      return if context_name.nil?

      get_cluster_contexts(kubeconfig).detect { |c| c['name'] == context_name }
    end

    def update_current_context(kubeconfig, current_context)
      new_kubeconfig = kubeconfig.deep_dup
      new_kubeconfig['current-context'] = current_context

      new_kubeconfig
    end

    def save_to_filepath(filepath, kubeconfig = nil)
      target_kubeconfig = read_kubeconfig(filepath)

      if target_kubeconfig.present? && !valid_kubeconfig?(target_kubeconfig)
        raise InvalidKubeconfigError.new(filepath)
      end

      new_kubeconfig = block_given? ? yield(target_kubeconfig) : kubeconfig
      return if new_kubeconfig.nil?

      write_kubeconfig(filepath, new_kubeconfig)
    end

    def default_path
      path = kubeconfig_env_path || Uffizzi.configuration.default_kubeconfig_path

      File.expand_path(path)
    end

    def read_kubeconfig(filepath)
      real_file_path = File.expand_path(filepath)
      kubeconfig = File.exist?(real_file_path) ? Psych.safe_load(File.read(real_file_path)) : nil

      if kubeconfig.present? && !valid_kubeconfig?(kubeconfig)
        raise InvalidKubeconfigError.new(filepath)
      end

      kubeconfig
    end

    def write_kubeconfig(filepath, kubeconfig)
      real_file_path = File.expand_path(filepath)
      dir_path = File.dirname(real_file_path)
      FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)
      File.write(real_file_path, kubeconfig.to_yaml)
    end

    private

    def cluster_exists_in_kubeconfig?(kubeconfig, cluster_name)
      clusters = kubeconfig['clusters'] || []
      clusters.detect { |c| c['name'] == cluster_name }.present?
    end

    def add(target_kubeconfig, source_kubeconfig)
      new_kubeconfig = target_kubeconfig.deep_dup
      new_kubeconfig['clusters'] << source_kubeconfig['clusters'][0]
      new_kubeconfig['contexts'] << source_kubeconfig['contexts'][0]
      new_kubeconfig['users'] << source_kubeconfig['users'][0]

      new_kubeconfig
    end

    def replace_by_cluster_name(target_kubeconfig, source_kubeconfig, cluster_name)
      new_kubeconfig = exclude_by_cluster_name(target_kubeconfig, cluster_name)

      add(new_kubeconfig, source_kubeconfig)
    end

    def exclude_by_cluster_name(kubeconfig, cluster_name)
      clusters = kubeconfig['clusters']
      contexts = kubeconfig['contexts']
      users = kubeconfig['users']

      return kubeconfig if clusters.empty? || contexts.empty? || users.empty?

      target_user = contexts.detect { |c| c.dig('context', 'cluster') == cluster_name }.dig('context', 'user')
      new_clusters = clusters.reject { |c| c['name'] == cluster_name }
      new_contexts = contexts.reject { |c| c.dig('context', 'cluster') == cluster_name }
      new_users = users.reject { |c| c['name'] == target_user }

      kubeconfig.merge({ 'clusters' => new_clusters, 'contexts' => new_contexts, 'users' => new_users })
    end

    def kubeconfig_env_path
      file_paths = ENV['KUBECONFIG']
      return if file_paths.blank?

      file_paths.split(':').first
    end

    def valid_kubeconfig?(data)
      return false unless data.is_a?(Hash)

      data_keys = data.keys.map(&:to_s)

      KUBECONFIG_GENERAL_KEYS.all? { |k| data_keys.include?(k) }
    end
  end
end
