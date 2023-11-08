# frozen_string_literal: true

require 'uffizzi/services/cluster_service'
require 'uffizzi/services/cluster/delete_service'
require 'uffizzi/services/dev_service'
require 'uffizzi/services/kubeconfig_service'
require 'uffizzi/auth_helper'

module Uffizzi
  class Cli::Dev < Thor
    include ApiClient

    desc 'ingress', 'Show the compose dev environment ingress info'
    require_relative 'dev/ingress'
    subcommand 'ingress', Uffizzi::Cli::Dev::Ingress

    desc 'start [CONFIG]', 'Start dev environment'
    method_option :quiet, type: :boolean, aliases: :q
    method_option :'default-repo', type: :string
    method_option :kubeconfig, type: :string
    method_option :'k8s-version', required: false, type: :string
    def start(config_path = 'skaffold.yaml')
      run('start', config_path: config_path)
    end

    desc 'stop', 'Stop dev environment'
    def stop
      run('stop')
    end

    desc 'describe', 'Describe dev environment'
    def describe
      run('describe')
    end

    desc 'delete', 'Delete dev environment'
    def delete
      run('delete')
    end

    private

    def run(command, command_args = {})
      Uffizzi::AuthHelper.check_login

      case command
      when 'start'
        handle_start_command(command_args)
      when 'stop'
        handle_stop_command
      when 'describe'
        handle_describe_command
      when 'delete'
        handle_delete_command
      end
    end

    def handle_start_command(command_args)
      DevService.check_skaffold_existence

      config_path = command_args[:config_path]
      DevService.check_skaffold_config_existence(config_path)
      dev_cluster = DevService.account_user_project_dev_cluster(server, account_id, project_slug)

      if try_to_start_second_dev_env?(dev_cluster)
        msg = 'Dev cluster already exists. ' \
              "Before you create a new dev cluster, you must delete the existing one: $ uffizzi cluster delete #{dev_cluster[:name]}"
        Uffizzi.ui.say_error_and_exit(msg)
      end

      if dev_cluster_already_deleted?(dev_cluster)
        DevService.clear_after_delete(dev_environment[:cluster_id], dev_environment[:encoded_kubeconfig])
        answer = Uffizzi.prompt.yes?('The previous development environment has been deleted. Do you want to start a new one?')

        return unless answer
      end

      DevService.check_no_running_process!

      unless DevService.dev_environment_exist?
        DevService.set_startup_state
        cluster_name = start_create_cluster
        cluster_data = wait_cluster_creation(cluster_name)
        DevService.set_dev_environment_config(cluster_name, config_path: config_path,
                                                            cluster_id: cluster_data[:id],
                                                            encoded_kubeconfig: cluster_data[:kubeconfig])
        DevService.set_cluster_deployed_state
      end

      if options[:quiet]
        launch_demonise_skaffold(config_path)
      else
        launch_basic_skaffold(config_path)
      end
    end

    def handle_stop_command
      DevService.check_running_process!
      DevService.stop_process
      Uffizzi.ui.say('Uffizzi dev was stopped')
    end

    def handle_describe_command
      DevService.check_environment_exist!

      cluster_data = fetch_dev_env_cluster!
      cluster_render_data = ClusterService.build_render_data(cluster_data)
      dev_environment_render_data = cluster_render_data.merge(config_path: dev_environment[:config_path])

      Uffizzi.ui.output_format = Uffizzi::UI::Shell::PRETTY_LIST
      Uffizzi.ui.say(dev_environment_render_data)
    end

    def handle_delete_command
      DevService.check_environment_exist!

      if DevService.process_running?
        DevService.stop_process
        Uffizzi.ui.say('Uffizzi dev was stopped')
      end

      cluster_data = fetch_dev_env_cluster!
      ClusterDeleteService.delete(cluster_data[:name], cluster_api_connection_params)
      DevService.clear_after_delete(cluster_data[:id], cluster_data[:kubeconfig])
    end

    def start_create_cluster
      params = cluster_creation_params
      Uffizzi.ui.say('Start creating a cluster')
      response = create_cluster(server, project_slug, params)
      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.created?(response)

      response.dig(:body, :cluster, :name)
    end

    def wait_cluster_creation(cluster_name)
      Uffizzi.ui.say('Checking the cluster status...')
      cluster_data = ClusterService.wait_cluster_deploy(project_slug, cluster_name, oidc_token)

      if ClusterService.failed?(cluster_data[:state])
        Uffizzi.ui.say_error_and_exit("Cluster with name: #{cluster_name} failed to be created.")
      end

      handle_succeed_cluster_creation(cluster_data)
    end

    def handle_succeed_cluster_creation(cluster_data)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      parsed_kubeconfig = ClusterCommonService.parse_kubeconfig(cluster_data[:kubeconfig])
      cluster_name = cluster_data[:name]

      Uffizzi.ui.say("Cluster with name: #{cluster_name} was created.")

      ClusterCreateService.save_kubeconfig(parsed_kubeconfig, kubeconfig_path, update_current_context: true)
      ClusterCommonService.update_clusters_config(cluster_data[:id], name: cluster_name, kubeconfig_path: kubeconfig_path)

      cluster_data
    end

    def cluster_creation_params
      {
        cluster: {
          name: ClusterService.generate_name,
          manifest: nil,
          creation_source: ClusterService::MANUAL_CREATION_SOURCE,
          k8s_version: options[:"k8s-version"],
          kind: ClusterService::DEV_CLUSTER_KIND,
        },
        token: oidc_token,
      }
    end

    def launch_demonise_skaffold(config_path)
      Uffizzi.process.daemon(true)

      Uffizzi.at_exit do
        DevService.stop_process
      end

      DevService.save_pid
      File.delete(DevService.logs_path) if File.exist?(DevService.logs_path)
      DevService.start_check_pid_file_existence
      DevService.run_check_cluster_existence(server, account_id, project_slug)
      DevService.start_demonised_skaffold(config_path, options)
    rescue StandardError => e
      File.open(DevService.logs_path, 'a') { |f| f.puts(e.message) }
    end

    def launch_basic_skaffold(config_path)
      Uffizzi.at_exit do
        DevService.stop_process
      end

      DevService.save_pid
      DevService.start_check_pid_file_existence
      DevService.run_check_cluster_existence(server, account_id, project_slug)
      DevService.start_basic_skaffold(config_path, options)
    end

    def fetch_dev_env_cluster!
      if DevService.startup?
        Uffizzi.ui.say_error_and_exit('Dev environment not started yet')
      end

      cluster_name = dev_environment[:cluster_name]
      ClusterService.fetch_cluster_data(cluster_name, **cluster_api_connection_params)
    end

    def dev_environment
      DevService.dev_environment
    end

    def dev_cluster_already_deleted?(dev_cluster)
      DevService.dev_environment_exist? && dev_cluster.blank?
    end

    def try_to_start_second_dev_env?(dev_cluster)
      !DevService.dev_environment_exist? && dev_cluster.present?
    end

    def cluster_api_connection_params
      {
        server: server,
        project_slug: project_slug,
        oidc_token: oidc_token,
      }
    end

    def project_slug
      @project_slug ||= ConfigFile.read_option(:project)
    end

    def oidc_token
      @oidc_token ||= ConfigFile.read_option(:oidc_token)
    end

    def server
      @server ||= ConfigFile.read_option(:server)
    end

    def account_id
      @account_id ||= ConfigFile.read_option(:account, :id)
    end
  end
end
