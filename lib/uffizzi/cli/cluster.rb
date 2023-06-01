# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/services/preview_service'
require 'uffizzi/services/command_service'

module Uffizzi
  class Cli::Cluster < Thor
    include ApiClient

    desc 'create [COMPOSE_FILE]', 'Create a cluster'
    def create
      run('create')
    end

    private

    def run(command, file_path: nil, deployment_name: nil)
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
      Uffizzi.ui.disable_stdout if Uffizzi.ui.output_format
      params = prepare_params(file_path, labels, creation_source)

      response = create_cluster(ConfigFile.read_option(:server), project_slug, params)

      if !ResponseHelper.created?(response)
        ResponseHelper.handle_failed_response(response)
      end

      cluster = response[:body][:cluster]
      Uffizzi.ui.say("Cluster with name: #{cluster[:name]} was created.")
      cluster_data = build_cluster_data(cluster)

      handle_result(cluster_data)
    rescue SystemExit, Interrupt, SocketError
      handle_interruption(cluster, ConfigFile.read_option(:server), project_slug)
    end

    def prepare_params(file_path, labels, creation_source = nil)
      compose_file_params = file_path.nil? ? {} : build_compose_file_params(file_path)
      metadata_params = labels.nil? ? {} : build_metadata_params(labels)
      token = ConfigFile.read_option(:token)
      extra_params = token.nil? ? {} : { token: token }
      params = compose_file_params.merge(metadata_params)
      params.merge(extra_params, { creation_source: creation_source })
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

    def handle_result(deployment_data)
      Uffizzi.ui.enable_stdout
      Uffizzi.ui.say(deployment_data) if Uffizzi.ui.output_format
      GithubService.write_to_github_env_if_needed(deployment_data)
    end

    def build_cluster_data(cluster)
      {
        name: cluster[:name],
      }
    end
  end
end
