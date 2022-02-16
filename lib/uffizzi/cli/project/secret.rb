# frozen_string_literal: true

require 'uffizzi'
require 'thor'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/shell'
require 'io/console'
require 'byebug'
module Uffizzi
  class CLI::Project::Secret < Thor
    include ApiClient

    desc 'list', 'List Secrets'
    def list
      return Uffizzi.ui.say('You are not logged in') unless AuthHelper.signed_in?

      project_slug = ConfigFile.read_option(:project)
      return Uffizzi.ui.say('Please use the --project option to specify the project name') if project_slug.nil?

      hostname = ConfigFile.read_option(:hostname)
      project_slug = ConfigFile.read_option(:project)
      response = fetch_secrets(hostname, project_slug)
      return Uffizzi.ui.say(response[:body]) if ResponseHelper.ok?(response)

      handle_failed_response(response)
    end

    desc 'create', 'Create secrets'
    def create(secret_name)
      bulk_create_secrets(@hostname, @project_slug, params)
    end

    desc 'delete', 'Delete a secret'
    def delete(id)
      project_slug = ConfigFile.read_option(:project)
      return Uffizzi.ui.say('Please use the --project option to specify the project name') if project_slug.nil?

      hostname = ConfigFile.read_option(:hostname)
      delete_secret(hostname, project_slug, id)
    end

    private

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end
  end
end
