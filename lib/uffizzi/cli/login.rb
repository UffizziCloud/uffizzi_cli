# frozen_string_literal: true

require 'io/console'
require 'json'
require 'uffizzi'

module Uffizzi
  class CLI::Login
    def initialize(options)
      @options = options
    end

    def run
      password = IO::console.getpass('Enter Password: ')

      params = {
        user: @options[:user],
        password: password.strip,
      }
      response = HttpClient.make_request(params, @options[:hostname])

      case response
      when Net::HTTPCreated
        account_data = {
          id: HttpClient.get_body_from_response(response)['user']['accounts'].first['id'],
        }
        data = {
          account: account_data,
          hostname: @options[:hostname],
          cookie: HttpClient.get_cookie_from_response(response),
        }
        Config.write(data)
      else
        puts HttpClient.get_body_from_response(response)['errors'].first.pop
      end
    end
  end
end
