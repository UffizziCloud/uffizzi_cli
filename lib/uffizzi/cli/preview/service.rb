# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/services/preview_service'

module Uffizzi
  class CLI::Preview::Service < Thor
    include ApiClient

    desc 'list', 'list'
    def list(deployment_name)
      return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?
      return Uffizzi.ui.say('This command needs project to be set in config file') unless Uffizzi::AuthHelper.project_set?

      project_slug = ConfigFile.read_option(:project)
      hostname = ConfigFile.read_option(:hostname)
      deployment_id = PreviewService.read_deployment_id(deployment_name)
      response = fetch_deployment_services(hostname, project_slug, deployment_id)

      if ResponseHelper.ok?(response)
        handle_succeed_response(response, deployment_name)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def handle_succeed_response(response, deployment_name)
      services = response[:body][:containers] || []
      return Uffizzi.ui.say("There are no services associated with the preview #{deployment_name}") if services.empty?

      services.each do |service|
        Uffizzi.ui.say(service)
      end
    end
  end
end
