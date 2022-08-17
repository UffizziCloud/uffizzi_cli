# frozen_string_literal: true

require 'uffizzi'

module Uffizzi
  class Cli < Thor
    class_option :project, type: :string

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Print version information for uffizzi CLI'
    def version
      require_relative 'version'
      Uffizzi.ui.say(Uffizzi::VERSION)
    end

    desc 'login [OPTIONS]', 'Login to Uffizzi to view and manage your previews'
    method_option :server, required: false, aliases: '-s'
    method_option :username, required: false, aliases: '-u'
    def login
      require_relative 'cli/login'
      Login.new(options).run
    end

    desc 'login_by_identity_token [OPTIONS]', 'Login or register to Uffizzi to view and manage your previews'
    method_option :server, required: true, aliases: '-s'
    method_option :token, required: true, aliases: '-t'
    def login_by_identity_token
      require_relative 'cli/login_by_identity_token'
      LoginByIdentityToken.new(options).run
    end

    desc 'logout', 'Log out of a Uffizzi user account'
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

    desc 'connect', 'connect'
    require_relative 'cli/connect'
    subcommand 'connect', Cli::Connect

    desc 'disconect CREDENTIAL_TYPE', 'Revoke a Uffizzi user account access to external services'
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
      rescue Interrupt
        raise Uffizzi::Error.new('The command was interrupted')
      rescue StandardError => e
        raise Uffizzi::Error.new(e.message)
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
