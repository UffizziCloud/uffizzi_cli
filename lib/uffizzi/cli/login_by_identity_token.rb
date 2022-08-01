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
      token = ENV['OIDC_TOKEN']
      params = prepare_request_params(token)
      server = ENV['UFFIZZI_SERVER']
      response = create_ci_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(token)
      {
        user: {
          token: token,
        },
      }
    end

    def handle_succeed_response(response, server)
      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, response[:body][:account_id])
      ConfigFile.write_option(:project, response[:body][:project_slug])
    end
  end
end
