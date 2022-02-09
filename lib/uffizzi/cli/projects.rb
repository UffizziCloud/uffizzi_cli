# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/auth_helper'

module Uffizzi
  class CLI::Projects
    include ApiClient

    def run
      return 'You are not logged in' unless Uffizzi::AuthHelper.signed_in?

      hostname = ConfigFile.read_option(:hostname)
      response = fetch_projects(hostname)

      if response[:code] == Net::HTTPOK
        handle_succeed_response(response)
      else
        handle_failed_response(response)
      end
    end

    private

    def handle_failed_response(response)
      ApiClient.print_errors(response[:body][:errors])
    end

    def handle_succeed_response(response)
      projects = response[:body][:projects]
      if projects.empty?
        puts 'No projects related to this email'
        return
      end
      if projects.size == 1
        ConfigFile.write_option(:project, projects.first[:slug])
      end
      print_projects(projects)
    end

    def print_projects(projects)
      projects.each do |project|
        puts (project[:slug]).to_s
      end
    end
  end
end
