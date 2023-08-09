# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'
require 'uffizzi/helpers/config_helper'

module Uffizzi
  class Cli::LoginByIdentityToken
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      oidc_token = @options[:oidc_token]
      github_access_token = @options[:access_token]
      server = @options[:server]
      params = prepare_request_params(oidc_token, github_access_token)
      response = create_ci_session(server, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, server, oidc_token)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(oidc_token, github_access_token)
      {
        user: {
          token: oidc_token,
          github_access_token: github_access_token,
        },
      }
    end

    def handle_succeed_response(response, server, oidc_token)
      ConfigFile.write_option(:server, server)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account, Uffizzi::ConfigHelper.account_config(response[:body][:account_id]))
      ConfigFile.write_option(:project, response[:body][:project_slug])
      ConfigFile.write_option(:oidc_token, oidc_token)

      Uffizzi.ui.say('Successful Login by Identity Token')
    end
  end
end
