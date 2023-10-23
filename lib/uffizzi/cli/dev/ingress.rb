# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'

module Uffizzi
  class Cli::Dev::Ingress < Thor
    include ApiClient

    desc 'open', 'Open dev environment hosts'
    def open
      Uffizzi::AuthHelper.check_login
      DevService.check_running_process!

      if DevService.startup?
        Uffizzi.ui.say_error_and_exit('Dev environment not started yet')
      end

      dev_environment = DevService.dev_environment
      cluster_name = dev_environment[:cluster_name]
      params = { cluster_name: cluster_name }
      response = get_cluster_ingresses(server, project_slug, params)

      return ResponseHelper.handle_failed_response(response) unless ResponseHelper.ok?(response)

      ingress_hosts = response.dig(:body, :ingresses)
      urls = ingress_hosts.map { |host| "https://#{host}" }
      urls.each { |url| Uffizzi.launchy.open(url) { Uffizzi.ui.say(url) } }
    end

    private

    def server
      @server ||= ConfigFile.read_option(:server)
    end

    def project_slug
      @project_slug ||= ConfigFile.read_option(:project)
    end
  end
end
