# frozen_string_literal: true

require 'thor'

module Uffizzi
  class CLI < Thor
    desc 'version', 'show version'
    def version
      puts Uffizzi::VERSION
    end
  end
end
