# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/date_helper'
require 'uffizzi/shell'
require 'time'

module Uffizzi
  class CLI::Project::Secret < Thor
    include ApiClient

    desc 'list', 'List Secrets'
    def list
      run('list')
    end

    desc 'create [SECRET_ID]', 'Create secrets from $stdout'
    def create(id)
      run('create', id)
    end

    desc 'delete [SECRET_ID]', 'Delete a secret'
    def delete(id)
      run('delete', id)
    end

    private

    def run(command, id = nil)
      Cli::Common.show_manual(:project, :secret, command) if options[:help] || args.include?('help')
      return Uffizzi.ui.say('You are not logged in') unless AuthHelper.signed_in?

      project_slug = ConfigFile.read_option(:project)
      return Uffizzi.ui.say('Please use the --project option to specify the project name') if project_slug.nil?

      case command
      when 'list'
        handle_list_command(project_slug)
      when 'create'
        handle_create_command(project_slug, id)
      when 'delete'
        handle_delete_command(project_slug, id)
      else
        error_message = "The subcommand #{command} does not exist, please run 'uffizzi project secret help' \
        to get the list of available subcommands"
        raise Thor::Error.new(error_message)
      end
    end

    def handle_list_command(project_slug)
      server = ConfigFile.read_option(:server)
      response = fetch_secrets(server, project_slug)
      secrets = response[:body][:secrets]

      return Uffizzi.ui.say('There are no secrets for the project') if secrets.empty?

      current_date = Time.now.utc
      prepared_secrets = secrets.map do |secret|
        [
          secret[:name],
          DateHelper.count_distanse(current_date, Time.parse(secret[:created_at])),
          DateHelper.count_distanse(current_date, Time.parse(secret[:updated_at])),
        ]
      end
      table_header = ['NAME', 'CREATED', 'UPDATED']
      table_data = [table_header, *prepared_secrets]
      return Uffizzi.ui.print_table(table_data) if ResponseHelper.ok?(response)

      ResponseHelper.handle_failed_response(response)
    end

    def handle_create_command(project_slug, id)
      server = ConfigFile.read_option(:server)
      secret_value = $stdin.read
      return Uffizzi.ui.say('Please provide the secret value') if secret_value.nil?

      params = { secrets: [{ name: id, value: secret_value }] }
      response = bulk_create_secrets(server, project_slug, params)
      return Uffizzi.ui.say('The secret was successfully created') if ResponseHelper.created?(response)

      ResponseHelper.handle_failed_response(response)
    end

    def handle_delete_command(project_slug, id)
      server = ConfigFile.read_option(:server)
      response = delete_secret(server, project_slug, id)

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('The secret was successfully deleted')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end
  end
end
