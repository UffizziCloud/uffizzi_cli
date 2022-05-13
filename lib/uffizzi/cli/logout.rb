# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'

module Uffizzi
  class Cli::Logout
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      return Uffizzi.ui.say('You are not logged in') unless Uffizzi::AuthHelper.signed_in?

      server = ConfigFile.read_option(:server)
      destroy_session(server)

      AuthHelper.sign_out
      Uffizzi.ui.say('You have been successfully logged out')
    end
  end
end
