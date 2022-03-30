# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/preview_service'

module Uffizzi
  class CLI::Preview::Service < Thor
    include ApiClient
    LOGS_REQUIRED_ARGUMENTS_NUMBER = 3

    desc 'uffizzi preview service logs [LOGS_TYPE] [DEPLOYMENT_ID] [CONTAINER_NAME]', 'logs'
    def logs(logs_type, deployment_name, container_name = args)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?

      deployment_id = PreviewService.read_deployment_id(deployment_name)
      response = service_logs_response(logs_type, deployment_id, container_name)
      return Uffizzi.ui.say(response[:errors]) if response[:errors]

      if ResponseHelper.ok?(response)
        handle_succeed_logs_response(response, container_name)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    desc 'uffizzi preview service logs [DEPLOYMENT_ID]', 'list'
    def list(deployment_name)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?

      project_slug = ConfigFile.read_option(:project)
      hostname = ConfigFile.read_option(:hostname)
      deployment_id = PreviewService.read_deployment_id(deployment_name)
      response = fetch_deployment_services(hostname, project_slug, deployment_id)

      if ResponseHelper.ok?(response)
        handle_succeed_list_response(response, deployment_name)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def service_logs_response(logs_type, deployment_id, container_name)
      project_slug = ConfigFile.read_option(:project)
      hostname = ConfigFile.read_option(:hostname)

      case logs_type
      when 'container'
        fetch_deployment_service_logs(hostname, project_slug, deployment_id, container_name)
      else
        raise Uffizzi::Error.new('Unknown log type')
      end
    end

    def handle_succeed_list_response(response, deployment_name)
      services = response[:body][:containers] || []
      return Uffizzi.ui.say("There are no services associated with the preview #{deployment_name}") if services.empty?

      services.each do |service|
        Uffizzi.ui.say(service)
      end
    end

    def handle_succeed_logs_response(response, container_name)
      logs = response[:body][:logs] || []
      return Uffizzi.ui.say("The service #{container_name} has no logs") if logs.empty?

      logs.each do |log|
        Uffizzi.ui.say(log)
      end
    end
  end
end
