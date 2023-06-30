# frozen_string_literal: true

require 'psych'
require 'faker'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'
require 'uffizzi/services/cluster_service'
require 'uffizzi/services/kubeconfig_service'

module Uffizzi
  class Cli::Cluster < Thor
    class Error < StandardError; end
    include ApiClient

    desc 'list', 'List all clusters'
    method_option :filter, required: false, type: :string, aliases: '-f'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def list
      run('list')
    end

    desc 'create', 'Create a cluster'
    method_option :name, type: :string, required: false, aliases: '-n'
    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    method_option :manifest, type: :string, required: false, aliases: '-m'
    method_option :output, required: false, type: :string, aliases: '-o', enum: ['json', 'pretty-json']
    def create
      run('create')
    end

    desc 'delete [NAME]', 'Delete a cluster'
    def delete(name)
      run('delete', cluster_name: name)
    end

    method_option :name, type: :string, required: true, aliases: '-n'
    method_option :kubeconfig, type: :string, required: false, aliases: '-k'
    method_option :print, type: :boolean, required: false, aliases: '-p'
    method_option :quiet, type: :boolean, required: false, aliases: '-q'
    desc 'update-kubeconfig', 'Udpate the your kubeconfig'
    def update_kubeconfig
      run('update-kubeconfig')
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
      when 'delete'
        handle_delete_command(project_slug, command_args)
      when 'update-kubeconfig'
        handle_update_kubeconfig_command(project_slug)
      end
    end

    def handle_list_command(project_slug)
      filter = options[:filter]
      parsed_filter = if filter.nil?
        filter
      else
        {
          q: {
            name_equal: filter,
          },
        }
      end
      response = get_clusters(ConfigFile.read_option(:server), project_slug, parsed_filter)
      puts '------'
      puts 'list response'
      puts response
      puts '------'

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_create_command(project_slug)
      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format
      cluster_name = options[:name] || ClusterService.generate_name

      unless ClusterService.valid_name?(cluster_name)
        Uffizzi.ui.say_error_and_exit("Cluster name: #{cluster_name} is not valid.")
      end

      manifest_file_path = options[:manifest]
      params = cluster_params(cluster_name, manifest_file_path)
      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)
      puts '------'
      puts 'create response'
      puts response
      puts '------'

      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.created?(response)

      cluster_data = ClusterService.wait_cluster_deploy(project_slug, cluster_name)

      if ClusterService.failed?(cluster_data[:state])
        Uffizzi.ui.say_error_and_exit("Cluster with name: #{cluster_name} failed to be created.")
      end

      handle_succeed_create_response(cluster_data, options[:kubeconfig])
    rescue SystemExit, Interrupt, SocketError
      handle_interruption(cluster_data, ConfigFile.read_option(:server), project_slug)
    end

    def handle_delete_command(project_slug, command_args)
      cluster_name = command_args[:cluster_name]
      response = delete_cluster(ConfigFile.read_option(:server), project_slug, cluster_name)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Cluster #{cluster_name} deleted")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_update_kubeconfig_command(project_slug)
      cluster_name = options[:name]
      kubeconfig_path = options[:kubeconfig] || KubeconfigService.default_path
      response = get_cluster(Uffizzi::ConfigFile.read_option(:server), project_slug, cluster_name)
      return Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)

      cluster_data = response.dig(:body, :cluster)

      if cluster_data[:kubeconfig].nil? || cluster_data[:kubeconfig].empty?
        say_error_update_kubeconfig(cluster_data)
      end

      parsed_kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])

      return Uffizzi.ui.say(parsed_kubeconfig.to_yaml) if Uffizzi.ui.stdout_pipe? || options[:print]

      KubeconfigService.save_to_filepath(kubeconfig_path, parsed_kubeconfig) do |kubeconfig_by_path|
        merged_kubeconfig = KubeconfigService.merge(kubeconfig_by_path, parsed_kubeconfig)
        current_context = KubeconfigService.get_current_context(parsed_kubeconfig)
        KubeconfigService.update_current_context(merged_kubeconfig, current_context)
      end

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

    def cluster_params(name, manifest_file_path)
      manifest_content = load_manifest_file(manifest_file_path)

      {
        cluster: {
          name: name,
          manifest: manifest_content,
        },
      }
    end

    def load_manifest_file(file_path)
      return nil if file_path.nil?

      File.read(file_path)
    rescue Errno::ENOENT => e
      raise Uffizzi::Error.new(e.message)
    end

    def handle_interruption(cluster, server, project_slug)
      deletion_response = delete_cluster(server, project_slug, cluster[:name])
      deletion_message = if ResponseHelper.no_content?(deletion_response)
        "The cluster #{cluster[:name]} has been disabled."
      else
        "Couldn't disable the cluster #{cluster[:name]} - please disable manually."
      end

      raise Uffizzi::Error.new("The cluster creation was interrupted. #{deletion_message}")
    end

    def handle_succeed_list_response(response)
      clusters = response[:body][:clusters] || []
      raise Uffizzi::Error.new('The project has no active clusters') if clusters.empty?

      if Uffizzi.ui.output_format.nil?
        clusters = clusters.map { |cluster| "- #{cluster[:name]}" }.join("\n").strip
      end

      Uffizzi.ui.say(clusters)
    end

    def handle_succeed_create_response(cluster_data, kubeconfig_path)
      kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])
      rendered_cluster_data = render_cluster_data(cluster_data)

      Uffizzi.ui.enable_stdout
      Uffizzi.ui.say("Cluster with name: #{rendered_cluster_data[:name]} was created.")
      Uffizzi.ui.say(rendered_cluster_data) if Uffizzi.ui.output_format

      kubeconfig_path = kubeconfig_path.nil? ? KubeconfigService.default_path : kubeconfig_path
      KubeconfigService.save_to_filepath(kubeconfig_path, kubeconfig)
      GithubService.write_to_github_env(rendered_cluster_data) if GithubService.github_actions_exists?
    end

    def render_cluster_data(cluster_data)
      kubeconfig = parse_kubeconfig(cluster_data[:kubeconfig])
      new_cluster_data = cluster_data.slice(:name)
      new_cluster_data[:context_name] = kubeconfig['current-context']

      new_cluster_data
    end

    def parse_kubeconfig(kubeconfig)
      Psych.safe_load(Base64.decode64(kubeconfig))
    end
  end
end
