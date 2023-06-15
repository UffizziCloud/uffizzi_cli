# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'
require 'byebug'

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

    desc 'delete [NAME]', 'Delete a cluster'
    def delete
      run('delete', cluster_name)
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
      when 'delete'
        handle_delete_command(cluster_name, project_slug)
      end
    end

    def handle_create_command(project_slug)
      kubeconfig_path = options[:kubeconfig]
      raise Uffizzi::Error.new('The kubeconfig file path already exists') if File.exist?(kubeconfig_path)

      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format
      name = options[:name]
      manifest = options[:manifest]
      params = cluster_params(name, manifest)

      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)

      if !ResponseHelper.created?(response)
        ResponseHelper.handle_failed_response(response)
      end

      cluster_data = response[:body][:cluster]
      status = cluster_data.dig(:status, :ready)
      unless status
        10.times do
          response = get_cluster(ConfigFile.read_option(:server), project_slug, name)
          return ResponseHelper.handle_failed_response(response) unless ResponseHelper.ok?(response)

          cluster_data = response[:body][:cluster]
          puts '-------'
          puts cluster_data
          puts '-------'

          break if cluster_data.dig(:status, :ready)

          sleep(5)
        end
      end

      Uffizzi.ui.say("Cluster with name: #{cluster_data[:name]} was created.")

      handle_result(cluster_data, kubeconfig_path)
    rescue SystemExit, Interrupt, SocketError
      handle_interruption(cluster_data, ConfigFile.read_option(:server), project_slug)
    end

    def handle_delete_command(cluster_name, project_slug)
      response = delete_cluster(ConfigFile.read_option(:server), project_slug, cluster_name)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say("Cluster #{cluster_name} deleted")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def cluster_params(name, manifest)
      {
        cluster: {
          name: name,
          manifest: manifest,
        },
      }
    end

    def handle_interruption(cluster, server, project_slug)
      deletion_response = delete_cluster(server, project_slug, cluster_data[:name])
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
      kubeconfig = cluster_data.dig(:status, :kube_config)
      File.write(kubeconfig_path, Base64.decode64(kubeconfig))
      GithubService.write_to_github_env_if_needed(cluster_data)
    end
  end
end
