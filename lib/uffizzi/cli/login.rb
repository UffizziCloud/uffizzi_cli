# frozen_string_literal: true

require 'io/console'
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
      password = IO::console.getpass('Enter Password: ')
      params = prepare_request_params(password)
      response = create_session(@options[:hostname], params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(password)
      {
        user: {
          email: @options[:user],
          password: password.strip,
        },
      }
    end

    def handle_succeed_response(response)
      account = response[:body][:user][:accounts].first
      return Uffizzi.ui.say('No account related to this email') unless account_valid?(account)

      ConfigFile.create(account[:id], response[:headers], @options[:hostname])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
