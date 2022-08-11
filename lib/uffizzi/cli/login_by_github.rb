# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class Cli::LoginByGithub
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      server = set_server
      username = set_username
      token = set_token
      params = prepare_request_params(username, token)
      response = create_github_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server, username)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def set_server
      config_server = ConfigFile.exists? && ConfigFile.option_has_value?(:server) ? ConfigFile.read_option(:server) : nil
      @options[:server] || config_server
    end

    def set_username
      config_username = ConfigFile.exists? && ConfigFile.option_has_value?(:username) ? ConfigFile.read_option(:username) : nil
      @options[:username] || config_username
    end

    def set_token
      ENV['GITHUB_TOKEN']
    end

    def prepare_request_params(username, token)
      {
        user: {
          username: username,
          token: token,
        },
      }
    end

    def handle_succeed_response(response, server, username)
      account = response[:body][:user][:accounts].first
      return Uffizzi.ui.say('No account related to this email') unless account_valid?(account)

      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:username, username)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, account[:id])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
