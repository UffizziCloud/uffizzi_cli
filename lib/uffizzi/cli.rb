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

    desc 'projects', 'projects'
    def projects
      require_relative 'cli/projects'
      Projects.new.run
    end

    desc 'config', 'config'
    def config(command, property = nil, value = nil)
      require_relative 'cli/config'
      Config.new.run(command, property, value)
    end
  end
end
