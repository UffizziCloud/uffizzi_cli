# frozen_string_literal: true

require 'uffizzi'
require 'thor'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'io/console'
module Uffizzi
  class CLI::Project::Secret < Thor
    desc 'list', 'List Secrets'
    def list
      Secret.new('list').run
    end

    desc 'create', 'Create secrets'
    def create
      Secret.new('create').run
    end

    desc 'delete', 'Delete a secret'
    def delete
      Secret.new('delete').run
    end

    class Secret
      include ApiClient

      def initialize(command)
        @command = command
        @hostname = ConfigFile.read_option(:hostname)
        @project_slug = ConfigFile.read_option(:project)
      end

      def run
        return Uffizzi.ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

        case @command
        when 'list'
          handle_list_command
        when 'create'
          handle_create_command
        when 'delete'
          handle_delete_command
        end
      end

      def handle_list_command
        return Uffizzi.ui.say('You are not logged in') unless AuthHelper.signed_in?

        response = fetch_secrets(@hostname, @project_slug, params)
        return Uffizzi.ui.say(response[:body]) if ResponseHelper.ok?(response)

        handle_failed_response(response)
      end

      def handle_create_command
        bulk_create_secrets(@hostname, @project_slug, params)
      end

      def handle_delete_command
        delete_secret(@hostname, @project_slug, params)
      end

      def handle_failed_response(response)
        print_errors(response[:body][:errors])
      end
    end
  end
end
