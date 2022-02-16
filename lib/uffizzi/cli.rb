# frozen_string_literal: true

require 'thor'

module Uffizzi
  class CLI < Thor
    require_relative 'cli/common'

    class_option :help, type: :boolean, aliases: HELP_MAPPINGS

    desc 'version', 'Show Version'
    def version
      puts Uffizzi::VERSION
    end

    desc 'login', 'Login into Uffizzi'
    method_option :user, required: true, aliases: '-u'
    method_option :hostname, required: true, aliases: '-h'
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end

    desc 'logout', 'Logout from Uffizzi'
    argument :help, type: :string, required: false
    def logout
      return Cli::Common.show_manual(:logout) if has_help_option?(options)

      require_relative 'cli/logout'
      Logout.new.run
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

    private

    def has_help_option?(options)
      options[:help] || ARGV.last == 'help'
    end
  end
end
