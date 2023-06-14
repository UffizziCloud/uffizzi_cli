# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'

module Uffizzi
  class Cli::Cluster < Thor
    include ApiClient

    desc 'create [NAME] [KUBECONFIG] [MANIFEST]', 'Create a cluster'
    method_option :name, type: :string, required: true
    method_option :kubeconfig, type: :string, required: true
    method_option :manifest, type: :string, required: false
    def create
      run('create')
    end

    private

    def run(command)
      Uffizzi.ui.output_format = options[:output]
      raise Uffizzi::Error.new('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      raise Uffizzi::Error.new('This command needs project to be set in config file') unless CommandService.project_set?(options)

      project_slug = options[:project].nil? ? ConfigFile.read_option(:project) : options[:project]

      case command
      when 'create'
        handle_create_command(project_slug)
      end
    end

    def handle_create_command(project_slug)
      kubeconfig_path = options[:kubeconfig]
      raise Uffizzi::Error.new('The kubeconfig file path already exists') if File.exists?(kubeconfig_path)

      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format
      name = options[:name]
      manifest = options[:manifest]
      params = prepare_params(name, manifest)

      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)

      if !ResponseHelper.created?(response)
        ResponseHelper.handle_failed_response(response)
      end

      cluster = response[:body][:cluster]
      Uffizzi.ui.say("Cluster with name: #{cluster[:name]} was created.")
      cluster_data = build_cluster_data(cluster)

      handle_result(cluster_data, kubeconfig_path)
    rescue SystemExit, Interrupt, SocketError
      handle_interruption(cluster, ConfigFile.read_option(:server), project_slug)
    end

    def prepare_params(name, manifest)
      token = ConfigFile.read_option(:token)
      extra_params = token.nil? ? {} : { token: token }
      params = {
        name: name,
        manifest: manifest,
      }
      params.merge(extra_params)
    end

    def handle_interruption(cluster, server, project_slug)
      deletion_response = delete_cluster(server, project_slug, cluster_id)
      deletion_message = if ResponseHelper.no_content?(deletion_response)
        "The cluster #{cluster[:name]} has been disabled."
      else
        "Couldn't disable the cluster #{cluster[:name]} - please disable maually."
      end

      raise Uffizzi::Error.new("The cluster creation was interrupted. #{deletion_message}")
    end

    def handle_result(cluster_data, kubeconfig_path)
      Uffizzi.ui.enable_stdout
      Uffizzi.ui.say(cluster_data) if Uffizzi.ui.output_format
      File.write(kubeconfig_path, cluster_data[:kubeconfig_content])
      GithubService.write_to_github_env_if_needed(cluster_data)
    end

    def build_cluster_data(cluster)
      {
        name: cluster[:name],
        kubeconfig_content: cluster[:kubeconfig_content]
      }
    end
  end
end
