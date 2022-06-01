# frozen_string_literal: true

require 'io/console'
require 'tty-spinner'

require 'thor'
require 'uffizzi/error'
require 'uffizzi/shell'
require 'uffizzi/promt'
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

    def prompt
      @prompt ||= Uffizzi::UI::Prompt.new
    end

    def root
      @root ||= Pathname.new(File.expand_path('..', __dir__))
    end
  end
end
