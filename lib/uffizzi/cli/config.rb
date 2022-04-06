# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class CLI::Config < Thor
    include ApiClient

    class << self
      def help(_shell, _subcommand)
        Cli::Common.show_manual(:config)
      end
    end

    desc 'list', 'list'
    def list
      run('list')
    end

    desc 'get [PROPERTY]', 'get'
    def get_value(property)
      run('get', property)
    end

    desc 'set [PROPERTY] [VALUE]', 'set'
    def set(property, value)
      run('set', property, value)
    end

    desc 'unset [PROPERTY]', 'unset'
    def unset(property)
      run('unset', property)
    end

    desc 'setup', 'setup'
    def setup
      run('setup')
    end

    map('get-value' => :get_value)

    default_task :setup

    private

    def run(command, property = nil, value = nil)
      case command
      when 'list'
        handle_list_command
      when 'get'
        handle_get_command(property)
      when 'set'
        handle_set_command(property, value)
      when 'unset'
        handle_unset_command(property)
      when 'setup'
        handle_setup_command
      end
    end

    def handle_setup_command
      Uffizzi.ui.say("Configure the default properties that will be used to authenticate with your \
                      \nUffizzi API service and manage previews.\n")
      hostname = Uffizzi.ui.ask('Hostname: ', default: Uffizzi.configuration.default_hostname.to_s)
      project = Uffizzi.ui.ask('Project: ')
      ConfigFile.delete
      ConfigFile.write_option(:hostname, hostname)
      ConfigFile.write_option(:project, project)
      Uffizzi.ui.say('To login, run: uffizzi login')
    end

    def handle_list_command
      ConfigFile.list
    end

    def handle_get_command(property)
      option = ConfigFile.read_option(property.to_sym)
      message = option.nil? ? "The option #{property} doesn't exist in config file" : option

      Uffizzi.ui.say(message)
    end

    def handle_set_command(property, value)
      ConfigFile.write_option(property.to_sym, value)
      Uffizzi.ui.say("Updated property [#{property}]")
    end

    def handle_unset_command(property)
      ConfigFile.unset_option(property.to_sym)
      Uffizzi.ui.say("Unset property [#{property}]")
    end
  end
end
