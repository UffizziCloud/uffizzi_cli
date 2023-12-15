# frozen_string_literal: true

require 'psych'
require 'faker'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/cluster_service'
require 'uffizzi/services/cluster/common_service'
require 'uffizzi/services/cluster/create_service'
require 'uffizzi/services/cluster/delete_service'
require 'uffizzi/services/cluster/list_service'
require 'uffizzi/services/cluster/update_kubeconfig_service'
require 'uffizzi/services/kubeconfig_service'
require 'uffizzi/services/cluster/disconnect_service'

module Uffizzi
  class Cli::Cluster < Thor
    class Error < StandardError; end
    include ApiClient

    desc 'list', 'List all clusters'
    method_option :all, required: false, type: :boolean, aliases: '-a'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def list
      run('list')
    end

    desc 'create [CLUSTER_NAME]', 'Create a cluster'
    method_option :name, type: :string, required: false, aliases: '-n'
    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    method_option :manifest, type: :string, required: false, aliases: '-m'
    method_option :'update-current-context', type: :boolean, required: false, default: true
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    method_option :'creation-source', required: false, type: :string
    method_option :'k8s-version', required: false, type: :string
    def create(name = nil)
      run('create', { name: name })
    end

    desc 'describe [CLUSTER_NAME]', 'Describe a cluster'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def describe(name)
      run('describe', cluster_name: name)
    end

    desc 'delete [CLUSTER_NAME]', 'Delete a cluster'
    method_option :'delete-config', required: false, type: :boolean, default: true
    def delete(name)
      run('delete', cluster_name: name)
    end

    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    method_option :print, type: :boolean, required: false, aliases: '-p'
    method_option :quiet, type: :boolean, required: false, aliases: '-q'
    desc 'update-kubeconfig', 'Udpate your kubeconfig'
    def update_kubeconfig(name)
      run('update-kubeconfig', cluster_name: name)
    end

    method_option :kubeconfig, type: :string, aliases: '-k'
    method_option :ask, type: :boolean
    desc 'disconnect', 'Switch back to original kubeconfig current context'
    def disconnect
      run('disconnect')
    end

    desc 'sleep [CLUSTER_NAME]', 'Scales a Uffizzi cluster down to zero resource utilization'
    def sleep(name = nil)
      run('sleep', cluster_name: name)
    end

    desc 'wake [CLUSTER_NAME]', 'Scales up a Uffizzi cluster to its original resource'
    def wake(name = nil)
      run('wake', cluster_name: name)
    end

    private

    def run(command, command_args = {})
      Uffizzi.ui.output_format = options[:output]
      Uffizzi::AuthHelper.check_login(options[:project])

      case command
      when 'list'
        handle_list_command
      when 'create'
        handle_create_command(command_args)
      when 'describe'
        handle_describe_command(command_args)
      when 'delete'
        handle_delete_command(command_args)
      when 'update-kubeconfig'
        handle_update_kubeconfig_command(command_args)
      when 'disconnect'
        ClusterDisconnectService.handle(options)
      when 'sleep'
        handle_sleep_command(command_args)
      when 'wake'
        handle_wake_command(command_args)
      end
    end

    def handle_list_command
      is_all = options[:all]
      response = if is_all
        get_account_clusters(server, ConfigFile.read_option(:account, :id))
      else
        get_project_clusters(server, project_slug, oidc_token: oidc_token)
      end

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def handle_create_command(command_args)
      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format

      if options[:name]
        msg = 'DEPRECATION WARNING: The --name option is deprecated and will be removed in the newer versions.' \
              ' Please use a positional argument instead: uffizzi cluster create my-awesome-name'
        Uffizzi.ui.say(msg)
      end

      cluster_name = command_args[:name] || options[:name] || ClusterService.generate_name
      Uffizzi.ui.say_error_and_exit("Cluster name: #{cluster_name} is not valid.") unless ClusterService.valid_name?(cluster_name)

      unless ClusterService.valid_name?(cluster_name)
        Uffizzi.ui.say_error_and_exit("Cluster name: #{cluster_name} is not valid.")
      end

      params = cluster_creation_params(cluster_name)
      response = create_cluster(server, project_slug, params)

      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.created?(response)

      spinner = TTY::Spinner.new("[:spinner] Creating cluster #{cluster_name}...", format: :dots)
      spinner.auto_spin
      cluster_data = ClusterService.wait_cluster_deploy(cluster_name, cluster_api_connection_params)

      if ClusterService.failed?(cluster_data[:state])
        spinner.error
        Uffizzi.ui.say_error_and_exit("Cluster #{cluster_name} failed to be created.")
      end

      spinner.success
      handle_succeed_create_response(cluster_data)
    rescue SystemExit, Interrupt, SocketError
      handle_interrupt_creation(cluster_name)
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def handle_describe_command(command_args)
      cluster_data = ClusterService.fetch_cluster_data(command_args[:cluster_name], **cluster_api_connection_params)
      render_data = ClusterService.build_render_data(cluster_data)

      Uffizzi.ui.output_format = Uffizzi::UI::Shell::PRETTY_LIST
      Uffizzi.ui.say(render_data)
    end

    def handle_delete_command(command_args)
      cluster_name = command_args[:cluster_name]
      is_delete_kubeconfig = options[:'delete-config']

      return handle_delete_cluster(cluster_name) unless is_delete_kubeconfig

      cluster_data = ClusterService.fetch_cluster_data(command_args[:cluster_name], **cluster_api_connection_params)
      kubeconfig = ClusterCommonService.parse_kubeconfig(cluster_data[:kubeconfig])

      handle_delete_cluster(cluster_name)
      ClusterDeleteService.exclude_kubeconfig(cluster_data[:id], kubeconfig) if kubeconfig.present?
    end

    def handle_delete_cluster(cluster_name)
      params = {
        cluster_name: cluster_name,
        oidc_token: oidc_token,
      }
      response = delete_cluster(server, project_slug, params)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Cluster #{cluster_name} deleted")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_update_kubeconfig_command(command_args)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      cluster_name = command_args[:cluster_name]
      cluster_data = ClusterService.fetch_cluster_data(cluster_name, **cluster_api_connection_params)

      unless cluster_data[:kubeconfig].present?
        ClusterUpdateKubeconfigService.say_error_update_kubeconfig(cluster_data)
      end

      parsed_kubeconfig = ClusterCommonService.parse_kubeconfig(cluster_data[:kubeconfig])

      return Uffizzi.ui.say(parsed_kubeconfig.to_yaml) if options[:print]

      KubeconfigService.save_to_filepath(kubeconfig_path, parsed_kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, parsed_kubeconfig)
        new_current_context = KubeconfigService.get_current_context(parsed_kubeconfig)
        new_kubeconfig = KubeconfigService.update_current_context(merged_kubeconfig, new_current_context)

        next new_kubeconfig if kubeconfig_by_path.nil?

        previous_current_context = KubeconfigService.get_current_context(kubeconfig_by_path)
        ClusterCommonService.save_previous_current_context(kubeconfig_path, previous_current_context)
        new_kubeconfig
      end

      ClusterCommonService.update_clusters_config(cluster_data[:id], kubeconfig_path: kubeconfig_path)

      return if options[:quiet]

      Uffizzi.ui.say("Kubeconfig was updated by the path: #{kubeconfig_path}")

      synced_cluster_data = ClusterService.sync_cluster_data(command_args[:cluster_name], **cluster_api_connection_params)

      if ClusterService.scaled_down?(synced_cluster_data[:state])
        Uffizzi.ui.say('The cluster is scaled down.')
        handle_scale_up_cluster(cluster_name, cluster_api_connection_params)
      end
    end

    def handle_sleep_command(command_args)
      cluster_name = command_args[:cluster_name] || ConfigFile.read_option(:current_cluster)&.fetch(:name)
      return handle_missing_cluster_name_error if cluster_name.nil?

      handle_scale_down_cluster(cluster_name, cluster_api_connection_params)
    end

    def handle_wake_command(command_args)
      cluster_name = command_args[:cluster_name] || ConfigFile.read_option(:current_cluster)&.fetch(:name)
      return handle_missing_cluster_name_error if cluster_name.nil?

      handle_scale_up_cluster(cluster_name, cluster_api_connection_params)
    end

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

    def cluster_creation_params(cluster_name)
      manifest_content = load_manifest_file(options[:manifest])
      creation_source = options[:"creation-source"] || ClusterService::MANUAL_CREATION_SOURCE
      k8s_version = options[:"k8s-version"]

      {
        cluster: {
          name: cluster_name,
          manifest: manifest_content,
          creation_source: creation_source,
          k8s_version: k8s_version,
        },
        token: oidc_token,
      }
    end

    def load_manifest_file(file_path)
      return nil if file_path.nil?

      File.read(file_path)
    rescue Errno::ENOENT => e
      raise Uffizzi::Error.new(e.message)
    end

    def handle_interrupt_creation(cluster_name)
      deletion_response = delete_cluster(server, project_slug, cluster_name: cluster_name)
      deletion_message = if ResponseHelper.no_content?(deletion_response)
        "The cluster #{cluster_name} has been disabled."
      else
        "Couldn't disable the cluster #{cluster_name} - please disable manually."
      end

      raise Uffizzi::Error.new("The cluster creation was interrupted. #{deletion_message}")
    end

    def handle_succeed_list_response(response)
      clusters = response[:body][:clusters] || []
      raise Uffizzi::Error.new('The project has no active clusters') if clusters.empty?

      clusters_data = if Uffizzi.ui.output_format.nil?
        ClusterListService.render_plain_clusters(clusters)
      else
        clusters.map { |c| c.slice(:name, :project) }
      end

      Uffizzi.ui.say(clusters_data)
    end

    def handle_succeed_create_response(cluster_data)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      is_update_current_context = options[:'update-current-context']
      parsed_kubeconfig = ClusterCommonService.parse_kubeconfig(cluster_data[:kubeconfig])
      rendered_cluster_data = build_render_cluster_data!(cluster_data)

      Uffizzi.ui.enable_stdout
      Uffizzi.ui.say("Cluster with name: #{rendered_cluster_data[:name]} was created.")

      unless is_update_current_context
        Uffizzi.ui.say("To update the current context, run:\nuffizzi cluster update-kubeconfig #{cluster_data[:name]}")
      end

      Uffizzi.ui.say(rendered_cluster_data) if Uffizzi.ui.output_format

      ClusterCreateService.save_kubeconfig(parsed_kubeconfig, kubeconfig_path, is_update_current_context)
      ClusterCommonService.update_clusters_config(cluster_data[:id], name: cluster_data[:name], kubeconfig_path: kubeconfig_path)
      GithubService.write_to_github_env(rendered_cluster_data) if GithubService.github_actions_exists?
    end

    def build_render_cluster_data!(cluster_data)
      kubeconfig = ClusterCommonService.parse_kubeconfig(cluster_data[:kubeconfig])
      raise Uffizzi::Error.new('The kubeconfig data is empty') unless kubeconfig

      new_cluster_data = cluster_data.slice(:name)
      new_cluster_data[:context_name] = kubeconfig['current-context']

      new_cluster_data
    end

    def parse_kubeconfig(kubeconfig)
      return if kubeconfig.nil?

      Psych.safe_load(Base64.decode64(kubeconfig))
    end

    def handle_scale_up_cluster(cluster_name, cluster_api_connection_params)
      response = scale_up_cluster(cluster_api_connection_params[:server], project_slug, cluster_name)
      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.ok?(response)

      spinner = TTY::Spinner.new("[:spinner] Waking up cluster #{cluster_name}...", format: :dots)
      spinner.auto_spin
      cluster_data = ClusterService.wait_cluster_scale_up(cluster_name, cluster_api_connection_params)

      if ClusterService.failed_scaling_up?(cluster_data[:state])
        spinner.error
        Uffizzi.ui.say_error_and_exit("Failed to scale up cluster #{cluster_name}.")
      end

      spinner.success
      Uffizzi.ui.say("Cluster #{cluster_name} was successfully scaled up")
    end

    def handle_scale_down_cluster(cluster_name, cluster_api_connection_params)
      response = scale_down_cluster(cluster_api_connection_params[:server], project_slug, cluster_name)
      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.ok?(response)

      spinner = TTY::Spinner.new("[:spinner] Scaling down cluster #{cluster_name}...", format: :dots)
      spinner.auto_spin
      ClusterService.wait_cluster_scale_down(cluster_name, cluster_api_connection_params)

      spinner.success
      Uffizzi.ui.say("Cluster #{cluster_name} was successfully scaled down")
    end

    def handle_missing_cluster_name_error
      Uffizzi.ui.say("No kubeconfig found at #{KubeconfigService.default_path}")
      Uffizzi.ui.say('Please update the current context or provide a cluster name.')
      Uffizzi.ui.say('$uffizzi cluster sleep my-cluster')
    end

    def cluster_api_connection_params
      {
        server: server,
        project_slug: project_slug,
        oidc_token: oidc_token,
      }
    end

    def oidc_token
      @oidc_token ||= ConfigFile.read_option(:oidc_token)
    end

    def project_slug
      @project_slug ||= options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]
    end

    def server
      @server ||= ConfigFile.read_option(:server)
    end
  end
end
