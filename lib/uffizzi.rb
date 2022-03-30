# frozen_string_literal: true

require 'io/console'
require 'tty-spinner'

require 'uffizzi/error'
require 'uffizzi/shell'
require 'uffizzi/version'
require 'uffizzi/clients/api/api_client'
require 'uffizzi/clients/api/api_routes'
require 'uffizzi/config_file'
require_relative '../config/uffizzi'

module Uffizzi
  class << self
    def ui
      @ui ||= Uffizzi::UI::Shell.new
    end
  end
end
