# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class CLI < Thor
    require_relative 'cli/common'

    class_option :help, type: :boolean, aliases: HELP_MAPPINGS
    class_option :project, type: :string

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Show Version'
    def version
      require_relative 'version'
      Uffizzi.ui.say(Uffizzi::VERSION)
    end

    desc 'login [OPTIONS]', 'Login into Uffizzi'
    method_option :server, required: false, aliases: '-s'
    method_option :username, required: false, aliases: '-u'
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end

    desc 'logout', 'Logout from Uffizzi'
    def logout
      require_relative 'cli/logout'
      Logout.new(options).run
    end

    desc 'project', 'project'
    require_relative 'cli/project'
    subcommand 'project', Cli::Project

    desc 'config', 'config'
    require_relative 'cli/config'
    subcommand 'config', Cli::Config

    desc 'preview', 'preview'
    method_option :project, required: false
    require_relative 'cli/preview'
    subcommand 'preview', Cli::Preview

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

      require_relative 'cli/common'
      def dispatch(meth, given_args, given_opts, config)
        args, opts = Thor::Options.split(given_args)
        return Common.show_manual(filename(args)) if show_help?(args, opts)

        super
      end

      private

      def filename(args)
        args_without_help = args.reject { |arg| arg == 'help' }
        return 'uffizzi' if args_without_help.empty?

        "uffizzi-#{args_without_help.join('-')}"
      end

      def show_help?(args, opts)
        help_options = ['--help', '-h', '--help=true']
        args.empty? || args.include?('help') || opts.any? { |opt| help_options.include?(opt) }
      end
    end
  end
end
