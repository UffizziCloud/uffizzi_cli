# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/config_file'

module Uffizzi
  class Cli::Status < Thor
    include ApiClient

    default_task :describe

    desc 'describe', 'Show account status'
    def describe
      Uffizzi::AuthHelper.check_login

      account_name = ConfigFile.read_option(:account)[:name]
      response = fetch_account(ConfigFile.read_option(:server), account_name)

      if ResponseHelper.ok?(response)
        handle_describe_success_response(response)
      elsif ResponseHelper.not_found?(response)
        Uffizzi.ui.say("Account with name #{account_name} does not exist")
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def handle_describe_success_response(response)
      account = response[:body][:account]
      account_rendered_params = {
        account: account[:name],
        plan: "Uffizzi #{account[:product_name]}",
        api: account[:api_url],
        controller: account[:vclusters_controller_url],
      }

      Uffizzi.ui.output_format = Uffizzi::UI::Shell::PRETTY_LIST
      Uffizzi.ui.say(account_rendered_params)
    end
  end
end
