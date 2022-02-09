# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/response_helper'

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

      if Uffizzi::ResponseHelper.created?(response)
        handle_succeed_response(response)
      else
        handle_failed_response(response)
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

    def handle_failed_response(response)
      print_errors(response[:body][:errors])
    end

    def handle_succeed_response(response)
      account = response[:body][:user][:accounts].first
      return puts 'No account related to this email' unless account_valid?(account)

      account_id = account[:id]
      ConfigFile.create(account_id, response[:headers], @options[:hostname])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
