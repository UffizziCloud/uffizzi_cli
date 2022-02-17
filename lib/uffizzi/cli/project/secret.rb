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
      run('list')
    end

    desc 'create', 'Create secrets'
    def create(id)
      run('create', id)
    end

    desc 'delete', 'Delete a secret'
    def delete(id)
      run('delete', id)
    end

    private

    def run(command, args = {})
      return Uffizzi.ui.say('You are not logged in') unless AuthHelper.signed_in?

      project_slug = ConfigFile.read_option(:project)
      return Uffizzi.ui.say('Please use the --project option to specify the project name') if project_slug.nil?

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(project_slug, args)
      when 'delete'
        handle_delete_command(project_slug, args)
      else
        Uffizzi.ui.say("The subcommand #{command} does not exist, please run 'uffizzi project secret help' to get the list of available subcommands")
      end
    end

    def handle_list_command(project_slug)
      hostname = ConfigFile.read_option(:hostname)
      response = fetch_secrets(hostname, project_slug)
      secrets = response[:body][:secrets].map{ |secret| [secret[:name]] }
      table_header = "NAME"
      table_data = [[table_header], *secrets]
      return Uffizzi.ui.print_table(table_data) if ResponseHelper.ok?(response)

      handle_failed_response(response)
    end

    def handle_create_command(project_slug, id)
      hostname = ConfigFile.read_option(:hostname)
      secret_value = $stdin.read
      return Uffizzi.ui.say('Please provide the secret value') if secret_value.nil?

      params = { secrets: [{ name: id, value: secret_value }] }
      response = bulk_create_secrets(hostname, project_slug, params)
      return Uffizzi.ui.say('The secret was successfully created') if ResponseHelper.created?(response)

      handle_failed_response(response)
    end

    def handle_delete_command(project_slug, id)
      hostname = ConfigFile.read_option(:hostname)
      response = delete_secret(hostname, project_slug, id)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('The secret was successfully deleted') 
      else
        handle_failed_response(response)
      end
    end

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end
  end
end
