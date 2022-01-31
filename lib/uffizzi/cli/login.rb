# frozen_string_literal: true

require 'io/console'
require 'uffizzi'

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

      if response[:code] == Net::HTTPCreated
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
      unless account_valid?(response[:body][:user][:accounts].first)
        puts 'No account related to this email'
        return
      end
      account_id = response[:body][:user][:accounts].first[:id]
      ConfigFile.create(account_id, response[:headers], @options[:hostname])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
