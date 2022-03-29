# frozen_string_literal: true

require 'thor'
require 'uffizzi'

module Uffizzi
  class CLI < Thor
    require_relative 'cli/common'
    class_option :help, type: :boolean, aliases: ['-h', 'help']

    def self.exit_on_failure?
      true
    end

    desc 'version', 'show version'
    def version
      require_relative 'version'
      Uffizzi.ui.say(Uffizzi::VERSION)
    end

    desc 'login', 'Login into Uffizzi'
    method_option :user, required: true, aliases: '-u'
    method_option :hostname, required: true
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end

    desc 'logout', 'Logout from Uffizzi'
    def logout
      require_relative 'cli/logout'
      Logout.new(options).run
    end

    desc 'projects', 'projects'
    def projects
      require_relative 'cli/projects'
      Projects.new.run
    end

    desc 'project', 'project'
    require_relative 'cli/project'
    subcommand 'project', CLI::Project

    desc 'config', 'config'
    require_relative 'cli/config'
    subcommand 'config', CLI::Config

    desc 'preview', 'preview'
    method_option :project, required: false
    require_relative 'cli/preview'
    subcommand 'preview', CLI::Preview

    desc 'connect CREDENTIAL_TYPE', 'Connect credentials into Uffizzi'
    def connect(credential_type, credential_file_path = nil)
      require_relative 'cli/connect'
      Connect.new.run(credential_type, credential_file_path)
    end

    desc 'disconect CREDENTIAL_TYPE', 'Disonnect credentials from Uffizzi'
    def disconnect(credential_type)
      require_relative 'cli/disconnect'
      Disconnect.new.run(credential_type)
    end

    class << self
      protected

      def dispatch(meth, given_args, given_opts, config)
        args, opts = Thor::Options.split(given_args)
        args_without_help = args.reject { |arg| arg == 'help' }
        file_name = "uffizzi-#{args_without_help.join('-')}"
        show_help = given_args.include?('help') || opts.include?('--help') || opts.include?('-h')
        return Cli::Common.show_manual(file_name) if show_help

        super
      end
    end
  end
end
