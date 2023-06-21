# frozen_string_literal: true

require 'psych'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/command_service'
require 'uffizzi/services/kubeconfig_service'
require 'byebug'

module Uffizzi
  class Cli::Cluster::Kubeconfig < Thor
    include ApiClient

    method_option :path, type: :string, required: true
    desc 'update [CLUSTER_NAME]', 'Show the logs for a container service of a preview'
    def update(cluster_name)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless CommandService.project_set?(options)

      target_kubeconfig_path = options[:path]
      # response = get_cluster(Uffizzi::ConfigFile.read_option(:server), project_slug, cluster_name)
      # cluster_data = response.dig(:body, :cluster)
      # source_kubeconfig = Psych.safe_load(Base64.decode64(cluster_data[:kube_config]))
      target_kubeconfig = Psych.safe_load(File.read(target_kubeconfig_path))

      source_kubeconfig = Psych.safe_load(File.read('tmp/kubeconfig.yaml'))

      new_kubeconfig = if File.exist?(target_kubeconfig_path)
                         KubeconfigService.merge(target_kubeconfig, source_kubeconfig, cluster_name)
                       else
                         source_kubeconfig
                       end

      File.write(target_kubeconfig_path, new_kubeconfig)
    end
  end
end
