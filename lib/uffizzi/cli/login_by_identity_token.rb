# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class Cli::LoginByIdentityToken
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      token = @options[:token]
      access_token = @options[:access_token]
      server = @options[:server]
      params = prepare_request_params(token, access_token)
      response = create_ci_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server, token)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(token, access_token)
      {
        user: {
          token: token,
          access_token: access_token,
        },
      }
    end

    def handle_succeed_response(response, server, token)
      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, response[:body][:account_id])
      ConfigFile.write_option(:project, response[:body][:project_slug])
      ConfigFile.write_option(:token, token)

      Uffizzi.ui.say('Successful Login by Identity Token')
    end
  end
end
