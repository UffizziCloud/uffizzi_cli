# frozen_string_literal: true

require 'uffizzi/shell'
require 'uffizzi/version'
require 'uffizzi/clients/api/api_client'
require 'uffizzi/clients/api/api_routes'
require 'uffizzi/config_file'

module Uffizzi
  class Error < StandardError; end

  class << self
    def ui
      @ui ||= Uffizzi::UI::Shell.new
    end
  end
end
