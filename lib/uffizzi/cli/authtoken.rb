# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'
require 'uffizzi/response_helper'

module Uffizzi
  class CLI::Authtoken < Thor
    include ApiClient

    desc 'create', 'generate token for docker extension auth'
    def create
      run('create')
    end

    private

    def run(command)
      case command
      when 'create'
        handle_create_command
      end
    end

    def handle_create_command
      server = options[:server]
      response = generate_token(server)

      if ResponseHelper.created?(response)
        handle_succeed_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_response(response)
      token = response[:body][:docker_extension_auth_token][:code]
      Uffizzi.ui.say(token)
    end
  end
end
