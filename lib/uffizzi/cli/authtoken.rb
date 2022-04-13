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

    desc 'show', 'shows token for docker extension auth'
    def show(authtoken_code)
      run('show', authtoken_code: authtoken_code)
    end

    private

    def run(command, authtoken_code: nil)
      case command
      when 'create'
        handle_create_command
      when 'show'
        handle_show_command(authtoken_code)
      end
    end

    def handle_create_command
      server = options[:server]
      response = create_token(server)

      if ResponseHelper.created?(response)
        handle_succeed_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_show_command(authtoken_code)
      server = options[:server]
      response = show_token(server, authtoken_code)

      if ResponseHelper.ok?(response)
        handle_show_response(response)
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def handle_succeed_response(response)
      token = response[:body][:docker_extension_auth_token][:code]
      Uffizzi.ui.say(token)
    end

    def handle_show_response(response)
      Uffizzi.ui.say(response[:body][:docker_extension_auth_token])
    end
  end
end
