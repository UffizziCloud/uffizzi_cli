# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'
require 'uffizzi/helpers/config_helper'

module Uffizzi
  class Cli::Account < Thor
    include ApiClient

    desc 'list', "List all user's accounts"
    def list
      run('list')
    end

    desc 'set-default ACCOUNT_NAME', 'set-default'
    def set_default(account_name)
      run('set-default', account_name)
    end

    map('set-default' => :set_default)
    map('set' => :set_default)

    private

    def run(command, account_name = nil)
      Uffizzi::AuthHelper.check_login

      case command
      when 'list'
        handle_list_command
      when 'set-default'
        handle_set_default_command(account_name)
      end
    end

    def handle_list_command
      server = ConfigFile.read_option(:server)
      response = fetch_accounts(server)

      if ResponseHelper.ok?(response)
        handle_list_success_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_set_default_command(account_name)
      response = fetch_account(ConfigFile.read_option(:server), account_name)

      if ResponseHelper.ok?(response)
        handle_succeed_set_default_response(response)
      elsif ResponseHelper.not_found?(response)
        Uffizzi.ui.say("Account with name #{account_name} does not exist")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_list_success_response(response)
      accounts = response[:body][:accounts]
      return Uffizzi.ui.say('No accounts found') if accounts.empty?

      print_accounts(accounts)
    end

    def print_accounts(accounts)
      accounts_list = accounts.reduce('') do |acc, account|
        "#{acc}#{account[:name]}\n"
      end
      Uffizzi.ui.say(accounts_list)
    end

    def handle_succeed_set_default_response(response)
      account = response[:body][:account]
      account_id = account[:id]
      account_name = account[:name]
      ConfigFile.write_option(:account, Uffizzi::ConfigHelper.account_config(account_id, account_name))
      Uffizzi.ui.say("The account with name '#{account_name}' was set as default.")

      projects = account[:projects]

      project = default_project(projects, account_id)
      if project.nil?
        ConfigFile.unset_option(:project)
        message = "There is no project set. Run the 'uffizzi project set-default' command to set a project"
        return Uffizzi.ui.say(message)
      end

      slug = project[:slug]
      ConfigFile.write_option(:project, slug)
      Uffizzi.ui.say("The project with slug '#{slug}' was set as default.")
    end

    def default_project(projects, account_id)
      return projects.first if projects.count == 1
      return create_default_project(account_id) if projects.count.zero?

      nil
    end

    def create_default_project(account_id)
      params = Uffizzi::ProjectHelper.generate_default_params
      response = create_project(ConfigFile.read_option(:server), account_id, params)

      if ResponseHelper.created?(response)
        handle_project_create_success_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_project_create_success_response(response)
      project = response[:body][:project]
      ConfigFile.write_option(:project, project[:slug])
      Uffizzi.ui.say("A default project '#{project[:name]}' was successfully created")

      project
    end
  end
end
