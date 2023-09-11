# frozen_string_literal: true

require 'psych'
require 'faker'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/helpers/config_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'
require 'uffizzi/services/cluster_service'
require 'uffizzi/services/kubeconfig_service'
require 'uffizzi/services/cluster/disconnect_service'

MANUAL = 'manual'

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

    desc 'create', 'Create a cluster'
    method_option :name, type: :string, required: false, aliases: '-n'
    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    method_option :manifest, type: :string, required: false, aliases: '-m'
    method_option :'update-current-context', type: :boolean, required: false
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    method_option :'creation-source', required: false, type: :string
    def create
      run('create')
    end

    desc 'describe [NAME]', 'Describe a cluster'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def describe(name)
      run('describe', cluster_name: name)
    end

    desc 'delete [NAME]', 'Delete a cluster'
    method_option :'delete-config', required: false, type: :boolean, aliases: '-c'
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

    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    desc 'disconnect', 'Switch back to original kubeconfig current context'
    def disconnect
      run('disconnect')
    end

    private

    def run(command, command_args = {})
      Uffizzi.ui.output_format = options[:output]
      raise Uffizzi::Error.new('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless CommandService.project_set?(options)

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(project_slug)
      when 'describe'
        handle_describe_command(project_slug, command_args)
      when 'delete'
        handle_delete_command(project_slug, command_args)
      when 'update-kubeconfig'
        handle_update_kubeconfig_command(project_slug, command_args)
      when 'disconnect'
        ClusterDisconnectService.handle(options)
      end
    end

    def handle_list_command(project_slug)
      is_all = options[:all]
      response = if is_all
        get_account_clusters(ConfigFile.read_option(:server), ConfigFile.read_option(:account, :id))
      else
        oidc_token = ConfigFile.read_option(:oidc_token)
        get_project_clusters(ConfigFile.read_option(:server), project_slug, oidc_token: oidc_token)
      end

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command(project_slug)
      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format
      cluster_name = options[:name] || ClusterService.generate_name
      creation_source = options[:"creation-source"] || MANUAL

      unless ClusterService.valid_name?(cluster_name)
        Uffizzi.ui.say_error_and_exit("Cluster name: #{cluster_name} is not valid.")
      end

      manifest_file_path = options[:manifest]
      params = cluster_creation_params(cluster_name, creation_source, manifest_file_path)
      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)

      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.created?(response)

      spinner = TTY::Spinner.new("[:spinner] Creating cluster #{cluster_name}...", format: :dots)
      spinner.auto_spin
      cluster_data = ClusterService.wait_cluster_deploy(project_slug, cluster_name, ConfigFile.read_option(:oidc_token))

      if ClusterService.failed?(cluster_data[:state])
        spinner.error
        Uffizzi.ui.say_error_and_exit("Cluster with name: #{cluster_name} failed to be created.")
      end

      spinner.success
      handle_succeed_create_response(cluster_data)
    rescue SystemExit, Interrupt, SocketError
      handle_interrupt_creation(cluster_name, ConfigFile.read_option(:server), project_slug)
    end

    def handle_describe_command(project_slug, command_args)
      cluster_data = fetch_cluster_data(project_slug, command_args[:cluster_name])

      handle_succeed_describe(cluster_data)
    end

    def handle_delete_command(project_slug, command_args)
      cluster_name = command_args[:cluster_name]
      is_delete_kubeconfig = options[:'delete-config']

      return handle_delete_cluster(project_slug, cluster_name) unless is_delete_kubeconfig

      cluster_data = fetch_cluster_data(project_slug, cluster_name)
      kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])

      handle_delete_cluster(project_slug, cluster_name)
      exclude_kubeconfig(cluster_data[:id], kubeconfig)
    end

    def exclude_kubeconfig(cluster_id, kubeconfig)
      cluster_config = Uffizzi::ConfigHelper.cluster_config_by_id(cluster_id)
      return if cluster_config.nil?

      kubeconfig_path = cluster_config[:kubeconfig_path]
      ConfigFile.write_option(:clusters, Uffizzi::ConfigHelper.clusters_config_without(cluster_id))

      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        if kubeconfig_by_path.nil?
          msg = "Warning: kubeconfig at path #{kubeconfig_path} does not exist"
          return Uffizzi.ui.say(msg)
        end

        new_kubeconfig = KubeconfigService.exclude(kubeconfig_by_path, kubeconfig)
        first_context = KubeconfigService.get_first_context(new_kubeconfig)
        new_current_context = first_context.present? ? first_context['name'] : nil
        KubeconfigService.update_current_context(new_kubeconfig, new_current_context)
      end
    end

    def handle_delete_cluster(project_slug, cluster_name)
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

    def handle_update_kubeconfig_command(project_slug, command_args)
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      cluster_data = fetch_cluster_data(project_slug, command_args[:cluster_name])

      unless cluster_data[:kubeconfig].present?
        say_error_update_kubeconfig(cluster_data)
      end

      parsed_kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])

      return Uffizzi.ui.say(parsed_kubeconfig.to_yaml) if options[:print]

      KubeconfigService.save_to_filepath(kubeconfig_path, parsed_kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, parsed_kubeconfig)
        new_current_context = KubeconfigService.get_current_context(parsed_kubeconfig)
        new_kubeconfig = KubeconfigService.update_current_context(merged_kubeconfig, new_current_context)

        next new_kubeconfig if kubeconfig_by_path.nil?

        previous_current_context = KubeconfigService.get_current_context(kubeconfig_by_path)
        save_previous_current_context(kubeconfig_path, previous_current_context)
        new_kubeconfig
      end

      update_clusters_config(cluster_data[:id], kubeconfig_path: kubeconfig_path)

      return if options[:quiet]

      Uffizzi.ui.say("Kubeconfig was updated by the path: #{kubeconfig_path}")
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

    def cluster_creation_params(name, creation_source, manifest_file_path)
      manifest_content = load_manifest_file(manifest_file_path)
      oidc_token = Uffizzi::ConfigFile.read_option(:oidc_token)

      {
        cluster: {
          name: name,
          manifest: manifest_content,
          creation_source: creation_source,
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

    def handle_interrupt_creation(cluster_name, server, project_slug)
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
        render_plain_cluster_list(clusters)
      else
        clusters.map { |c| c.slice(:name, :project) }
      end

      Uffizzi.ui.say(clusters_data)
    end

    def render_plain_cluster_list(clusters)
      clusters.map do |cluster|
        project_name = cluster.dig(:project, :name)

        if project_name.present?
          "- Cluster name: #{cluster[:name].strip} Project name: #{project_name.strip}"
        else
          "- #{cluster[:name]}"
        end
      end.join("\n")
    end

    def handle_succeed_describe(cluster_data)
      prepared_cluster_data = {
        name: cluster_data[:name],
        status: cluster_data[:state],
        created: Time.strptime(cluster_data[:created_at], '%Y-%m-%dT%H:%M:%S.%N').strftime('%a %b %d %H:%M:%S %Y'),
        url: cluster_data[:host],
      }

      rendered_cluster_data = if Uffizzi.ui.output_format.nil?
        prepared_cluster_data.map { |k, v| "- #{k.to_s.upcase}: #{v}" }.join("\n").strip
      else
        prepared_cluster_data
      end

      Uffizzi.ui.say(rendered_cluster_data)
    end

    def handle_succeed_create_response(cluster_data)
      kubeconfig_path = options[:kubeconfig]
      is_update_current_context = options[:'update-current-context']
      parsed_kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])
      rendered_cluster_data = render_cluster_data(cluster_data)

      Uffizzi.ui.enable_stdout
      Uffizzi.ui.say("Cluster with name: #{rendered_cluster_data[:name]} was created.")

      unless is_update_current_context
        Uffizzi.ui.say("To update the current context, run:\nuffizzi cluster update-kubeconfig #{cluster_data[:name]}")
      end

      Uffizzi.ui.say(rendered_cluster_data) if Uffizzi.ui.output_format

      save_kubeconfig(parsed_kubeconfig, kubeconfig_path)
      update_clusters_config(cluster_data[:id], kubeconfig_path: kubeconfig_path)
      GithubService.write_to_github_env(rendered_cluster_data) if GithubService.github_actions_exists?
    end

    def save_kubeconfig(kubeconfig, kubeconfig_path)
      kubeconfig_path = kubeconfig_path.nil? ? KubeconfigService.default_path : kubeconfig_path
      is_update_current_context = options[:'update-current-context']

      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, kubeconfig)

        if is_update_current_context
          new_current_context = KubeconfigService.get_current_context(kubeconfig)
          new_kubeconfig = KubeconfigService.update_current_context(merged_kubeconfig, new_current_context)

          next new_kubeconfig if kubeconfig_by_path.nil?

          previous_current_context = KubeconfigService.get_current_context(kubeconfig_by_path)
          save_previous_current_context(kubeconfig_path, previous_current_context)
          new_kubeconfig
        else
          merged_kubeconfig
        end
      end
    end

    def update_clusters_config(id, params)
      clusters_config = Uffizzi::ConfigHelper.update_clusters_config_by_id(id, params)
      ConfigFile.write_option(:clusters, clusters_config)
    end

    def render_cluster_data(cluster_data)
      kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])
      raise Uffizzi::Error.new('The kubeconfig data is empty') unless kubeconfig

      new_cluster_data = cluster_data.slice(:name)
      new_cluster_data[:context_name] = kubeconfig['current-context']

      new_cluster_data
    end

    def parse_kubeconfig(kubeconfig)
      Psych.safe_load(Base64.decode64(kubeconfig))
    end

    def fetch_cluster_data(project_slug, cluster_name)
      params = {
        cluster_name: cluster_name,
        oidc_token: ConfigFile.read_option(:oidc_token),
      }
      response = get_cluster(ConfigFile.read_option(:server), project_slug, params)

      if ResponseHelper.ok?(response)
        response.dig(:body, :cluster)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def save_previous_current_context(kubeconfig_path, current_context)
      return if kubeconfig_path.nil? || ConfigHelper.previous_current_context_by_path(kubeconfig_path).present?

      previous_current_contexts = Uffizzi::ConfigHelper.set_previous_current_context_by_path(kubeconfig_path, current_context)
      ConfigFile.write_option(:previous_current_contexts, previous_current_contexts)
    end
  end
end
