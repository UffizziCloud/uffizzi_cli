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

      params = {
        user: {
          email: @options[:user],
          password: password.strip,
        }
      }

      response = create_session(@options[:hostname], params)

      if response[:code] == Net::HTTPCreated
        unless account_valid?(response[:body][:user][:accounts].first)
          puts "No account related to this email"
          return
        end
        ConfigFile.create(response[:body], response[:headers], @options[:hostname])
      else
        response[:body][:errors].each { |error| puts error.pop }
      end
    end

    private

    def account_valid?(account)
      account[:state] == "active"
    end
  end
end
