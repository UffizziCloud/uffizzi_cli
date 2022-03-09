# frozen_string_literal: true

require 'thor'
require 'uffizzi'

module Uffizzi
  class CLI < Thor
    require_relative 'cli/common'

    class_option :help, type: :boolean, aliases: HELP_MAPPINGS

    desc 'version', 'Show Version'
    def version
      require_relative 'version'
      Uffizzi.ui.say(Uffizzi::VERSION)
    end

    desc 'login', 'Login into Uffizzi'
    method_option :user, required: true, aliases: '-u'
    method_option :hostname, required: true, aliases: '-h'
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end

    desc 'logout', 'Logout from Uffizzi'
    def logout(help = nil)
      return Cli::Common.show_manual(:logout) if help || options[:help]

      require_relative 'cli/logout'
      Logout.new.run
    end

    desc 'project', 'project'
    require_relative 'cli/project'
    subcommand 'project', CLI::Project

    desc 'config', 'config'
    require_relative 'cli/config'
    subcommand 'config', CLI::Config
  end
end
