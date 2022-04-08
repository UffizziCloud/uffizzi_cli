# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/auth_helper'

module Uffizzi
  class CLI::Logout
    include ApiClient

    def initialize(options)
      @options = options
    end

    def run
      return Uffizzi.ui.say('You are not logged in') unless Uffizzi::AuthHelper.signed_in?

      hostname = ConfigFile.read_option(:hostname)
      destroy_session(hostname)

      ConfigFile.delete
      Uffizzi.ui.say('You have been successfully logged out')
    end
  end
end
