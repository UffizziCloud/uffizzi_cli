# frozen_string_literal: true

require 'thor'

module Uffizzi
  class CLI < Thor
    desc 'version', 'show version'
    def version
      puts Uffizzi::VERSION
    end

    desc 'login', 'login'
    method_option :user, required: true, aliases: '-u'
    method_option :hostname, required: true, aliases: '-h'
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end
  end
end
