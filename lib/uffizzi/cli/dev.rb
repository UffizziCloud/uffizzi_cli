# frozen_string_literal: true

require 'uffizzi/services/command_service'
require 'uffizzi/services/cluster_service'
require 'uffizzi/services/dev_service'
require 'uffizzi/services/kubeconfig_service'

module Uffizzi
  class Cli::Dev < Thor
    include ApiClient

    desc 'start [CONFIG]', 'Start dev environment'
    method_option :quiet, type: :boolean, aliases: :q
    method_option :'default-repo', type: :string
    method_option :kubeconfig, type: :string
    def start(config_path = 'skaffold.yaml')
      DevService.check_skaffold_existence
      DevService.check_running_daemon if options[:quiet]
      DevService.check_skaffold_config_existence(config_path)
      check_login
      cluster_id, cluster_name = start_create_cluster
      kubeconfig = wait_cluster_creation(cluster_name)

      if options[:quiet]
        launch_demonise_skaffold(config_path)
      else
        DevService.start_basic_skaffold(config_path, options)
      end
    ensure
      if defined?(cluster_name).present? && defined?(cluster_id).present?
        kubeconfig = defined?(kubeconfig).present? ? kubeconfig : nil
        handle_delete_cluster(cluster_id, cluster_name, kubeconfig)
      end
    end

    desc 'stop', 'Stop dev environment'
    def stop
      return Uffizzi.ui.say('Uffizzi dev is not running') unless File.exist?(DevService.pid_path)

      pid = File.read(DevService.pid_path).to_i
      File.delete(DevService.pid_path)

      Uffizzi.process.kill('QUIT', pid)
      Uffizzi.ui.say('Uffizzi dev was stopped')
    rescue Errno::ESRCH
      Uffizzi.ui.say('Uffizzi dev is not running')
      File.delete(DevService.pid_path)
    end

    private

    def check_login
      raise Uffizzi::Error.new('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless CommandService.project_set?(options)
    end

    def start_create_cluster
      cluster_name = ClusterService.generate_name
      creation_source = ClusterService::MANUAL_CREATION_SOURCE
      params = cluster_creation_params(cluster_name, creation_source)
      Uffizzi.ui.say('Start creating a cluster')
      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)
      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.created?(response)

      cluster_id = response.dig(:body, :cluster, :id)
      cluster_name = response.dig(:body, :cluster, :name)

      [cluster_id, cluster_name]
    end

    def wait_cluster_creation(cluster_name)
      Uffizzi.ui.say('Checking the cluster status...')
      cluster_data = ClusterService.wait_cluster_deploy(project_slug, cluster_name, ConfigFile.read_option(:oidc_token))

      if ClusterService.failed?(cluster_data[:state])
        Uffizzi.ui.say_error_and_exit("Cluster with name: #{cluster_name} failed to be created.")
      end

      handle_succeed_cluster_creation(cluster_data)
      parse_kubeconfig(cluster_data[:kubeconfig])
    end

    def handle_succeed_cluster_creation(cluster_data)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      parsed_kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])

      Uffizzi.ui.say("Cluster with name: #{cluster_data[:name]} was created.")

      save_kubeconfig(parsed_kubeconfig, kubeconfig_path)
      update_clusters_config(cluster_data[:id], kubeconfig_path: kubeconfig_path)
    end

    def save_kubeconfig(kubeconfig, kubeconfig_path)
      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, kubeconfig)

        new_current_context = KubeconfigService.get_current_context(kubeconfig)
        new_kubeconfig = KubeconfigService.update_current_context(merged_kubeconfig, new_current_context)

        next new_kubeconfig if kubeconfig_by_path.nil?

        previous_current_context = KubeconfigService.get_current_context(kubeconfig_by_path)
        save_previous_current_context(kubeconfig_path, previous_current_context)
        new_kubeconfig
      end
    end

    def update_clusters_config(id, params)
      clusters_config = Uffizzi::ConfigHelper.update_clusters_config_by_id(id, params)
      ConfigFile.write_option(:clusters, clusters_config)
    end

    def cluster_creation_params(name, creation_source)
      oidc_token = Uffizzi::ConfigFile.read_option(:oidc_token)

      {
        cluster: {
          name: name,
          manifest: nil,
          creation_source: creation_source,
        },
        token: oidc_token,
      }
    end

    def handle_delete_cluster(cluster_id, cluster_name, kubeconfig)
      return if cluster_id.nil? || cluster_name.nil?

      exclude_kubeconfig(cluster_id, kubeconfig) if kubeconfig.present?

      params = {
        cluster_name: cluster_name,
        oidc_token: ConfigFile.read_option(:oidc_token),
      }
      response = delete_cluster(ConfigFile.read_option(:server), project_slug, params)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Cluster #{cluster_name} deleted")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def exclude_kubeconfig(cluster_id, kubeconfig)
      cluster_config = Uffizzi::ConfigHelper.cluster_config_by_id(cluster_id)
      return if cluster_config.nil?

      kubeconfig_path = cluster_config[:kubeconfig_path]
      ConfigFile.write_option(:clusters, Uffizzi::ConfigHelper.clusters_config_without(cluster_id))

      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        return if kubeconfig_by_path.nil?

        new_kubeconfig = KubeconfigService.exclude(kubeconfig_by_path, kubeconfig)
        new_current_context = find_previous_current_context(new_kubeconfig, kubeconfig_path)
        KubeconfigService.update_current_context(new_kubeconfig, new_current_context)
      end
    end

    def find_previous_current_context(kubeconfig, kubeconfig_path)
      prev_current_context = Uffizzi::ConfigHelper.previous_current_context_by_path(kubeconfig_path)&.fetch(:current_context, nil)

      if KubeconfigService.find_cluster_contexts_by_name(kubeconfig, prev_current_context).present?
        prev_current_context
      end
    end

    def save_previous_current_context(kubeconfig_path, current_context)
      previous_current_contexts = Uffizzi::ConfigHelper.set_previous_current_context_by_path(kubeconfig_path, current_context)
      ConfigFile.write_option(:previous_current_contexts, previous_current_contexts)
    end

    def parse_kubeconfig(kubeconfig)
      return if kubeconfig.nil?

      Psych.safe_load(Base64.decode64(kubeconfig))
    end

    def launch_demonise_skaffold(config_path)
      Uffizzi.process.daemon(true)

      at_exit do
        File.delete(DevService.pid_path) if File.exist?(DevService.pid_path)
      end

      File.delete(DevService.logs_path) if File.exist?(DevService.logs_path)
      File.write(DevService.pid_path, Uffizzi.process.pid)
      DevService.start_check_pid_file_existence
      DevService.start_demonised_skaffold(config_path, options)
    rescue StandardError => e
      File.open(DevService.logs_path, 'a') { |f| f.puts(e.message) }
    end

    def project_slug
      @project_slug ||= ConfigFile.read_option(:project)
    end
  end
end
