# frozen_string_literal: true

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
      if @options[:hostname].nil? && !ConfigFile.option_has_value?(:hostname)
        no_hostname_message = 'Uffizzi hostname is not set. To set hostname, run uffizzi config set hostname VALUE, ' \
                              'or to login with an alternate hostname, run uffizzi login --hostname=HOSTNAME'
        return Uffizzi.ui.say(no_hostname_message)
      end
      hostname = @options[:hostname] || ConfigFile.read_option(:hostname)
      Uffizzi.ui.say('Login to Uffizzi to your previews.')
      username = @options[:username] || Uffizzi.ui.ask('Username: ')
      password = ENV['UFFIZZI_PASSWORD'] || Uffizzi.ui.ask('Password: ', echo: false)
      params = prepare_request_params(username, password)
      response = create_session(hostname, params)

      if ResponseHelper.created?(response)
        handle_succeed_response(response, hostname)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def prepare_request_params(username, password)
      {
        user: {
          email: username,
          password: password,
        },
      }
    end

    def handle_succeed_response(response, hostname)
      account = response[:body][:user][:accounts].first
      return Uffizzi.ui.say('No account related to this email') unless account_valid?(account)

      ConfigFile.write_option(:hostname, hostname)
      ConfigFile.write_option(:cookie, response[:headers])
      ConfigFile.write_option(:account_id, account[:id])
    end

    def account_valid?(account)
      account[:state] == 'active'
    end
  end
end
