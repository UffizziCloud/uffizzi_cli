# frozen_string_literal: true

require 'io/console'
require 'json'
require 'uffizzi'

module Uffizzi
  class CLI::Login
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      password = IO::console.getpass('Enter Password: ')

      params = {
        user: {
          email: @options[:user],
          password: password.strip,
        },
      }

      response = create_session(@options[:hostname], params)

      if response[:code] == Net::HTTPCreated
        Config.write(response[:body], response[:cookie], @options[:hostname])
      else
        response[:body][:errors].each { |error| puts error.pop }
      end
    end
  end
end
