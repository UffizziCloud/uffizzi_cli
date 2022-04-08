# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class CLI::Login
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      if @options[:server].nil? && !ConfigFile.option_has_value?(:server)
        no_server_message = 'Uffizzi server is not set. To set server, run uffizzi config set server VALUE, ' \
                              'or to login with an alternate server, run uffizzi login --server=SERVER'
        return Uffizzi.ui.say(no_server_message)
      end
      server = @options[:server] || ConfigFile.read_option(:server)
      Uffizzi.ui.say('Login to Uffizzi to your previews.')
      username = @options[:username] || Uffizzi.ui.ask('Username: ')
      password = ENV['UFFIZZI_PASSWORD'] || Uffizzi.ui.ask('Password: ', echo: false)
      params = prepare_request_params(username, password)
      response = create_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(username, password)
      {
        user: {
          email: username,
          password: password,
        },
      }
    end

    def handle_succeed_response(response, server)
      account = response[:body][:user][:accounts].first
      return Uffizzi.ui.say('No account related to this email') unless account_valid?(account)

      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, account[:id])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
