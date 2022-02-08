# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/auth_helper'
require 'thor'

module Uffizzi
  class CLI::Project < Thor

    desc "compose", "compose"
    require_relative "project/compose"
    subcommand "compose", Uffizzi::CLI::Project::Compose

    desc 'list', 'list'
    def list
      options[:command] = 'list'
      Project.new(options).run
    end

    class Project
      include ApiClient

      def initialize(options)
        @options = options
      end

      def run
        return unless Uffizzi::AuthHelper.signed_in?

        case @options[:command]
        when 'list'
          handle_list_command
        end
      end

      private

      def handle_list_command
        hostname = ConfigFile.read_option(:hostname)
        response = fetch_projects(hostname)

        if response[:code] == Net::HTTPOK
          handle_succeed_response(response)
        else
          handle_failed_response(response)
        end
      end

      def handle_failed_response(response)
        print_errors(response[:body][:errors])
      end

      def handle_succeed_response(response)
        projects = response[:body][:projects]
        if projects.empty?
          Uffizzi.ui.say('No projects related to this email')
          return
        end
        if projects.size == 1
          ConfigFile.write_option(:project, projects.first[:slug])
        end
        print_projects(projects)
      end

      def print_projects(projects)
        projects.each do |project|
          Uffizzi.ui.say((project[:slug]).to_s)
        end
      end
    end
  end
end
