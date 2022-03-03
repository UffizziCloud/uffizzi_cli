# frozen_string_literal: true

require 'uffizzi/shell'
require_relative 'uffizzi/version'
require_relative 'uffizzi/clients/api/api_client'
require_relative 'uffizzi/clients/api/api_routes'
require_relative 'uffizzi/config_file'

module Uffizzi
  class Error < StandardError; end
  class << self
    def ui
      @ui ||= Uffizzi::UI::Shell.new
    end
  end
end
