# frozen_string_literal: true

require 'io/console'
require 'json'
require 'uffizzi'

module Uffizzi
  class CLI::Login
    include ApiClient
    include ApiResponse

    def initialize(options)
      @options = options
    end

    def run
      password = IO::console.getpass('Enter Password: ')

      params = {
        user: {
          email: @options[:user],
          password: password.strip,
        }
      }
      response = create_session(@options[:hostname], params)
      response_body = response_body(response)
      response_cookie = response_cookie(response)

      case response
      when Net::HTTPCreated
        data = prepare_config_data(response_body, response_cookie)
        Config.write(data)
      else
        puts response_body[:errors].first.pop
      end
    end

    private

    def prepare_config_data(response_body, response_cookie)
      account_data = {
        id: response_body[:user][:accounts].first[:id],
      }
      data = {
        account: account_data,
        hostname: @options[:hostname],
        cookie: response_cookie,
      }

      data
    end
  end
end
