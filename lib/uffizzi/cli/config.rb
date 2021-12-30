# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class CLI::Config < Thor
    include ApiClient

    desc 'list', 'list'
    def list
      run('list')
    end

    desc 'get', 'get'
    def get(property)
      run('get', property)
    end

    desc 'set', 'set'
    def set(property, value)
      run('set', property, value)
    end

    desc 'delete', 'delete'
    def delete(property)
      run('delete', property)
    end

    private

    def run(command, property = nil, value = nil)
      case command
      when 'list'
        handle_list_command
      when 'get'
        handle_get_command(property)
      when 'set'
        handle_set_command(property, value)
      when 'delete'
        handle_delete_command(property)
<<<<<<< HEAD
=======
      else
        Uffizzi.ui.say("#{command} is not a uffizzi config command")
>>>>>>> fixes after rebase
      end
    end

    def handle_list_command
      ConfigFile.list
    end

    def handle_get_command(property)
<<<<<<< HEAD
      option = ConfigFile.read_option(property.to_sym)
      message = option.nil? ? "The option #{property} doesn't exist in config file" : option

      Uffizzi.ui.say(message)
    end

    def handle_set_command(property, value)
=======
      if property.nil?
        Uffizzi.ui.say('No property provided')
        return
      end
      option = ConfigFile.read_option(property.to_sym)
      Uffizzi.ui.say(option) unless option.nil?
    end

    def handle_set_command(property, value)
      if property.nil? || value.nil?
        Uffizzi.ui.say('No property provided') if property.nil?
        Uffizzi.ui.say('No value provided') if value.nil?
        return
      end
>>>>>>> fixes after rebase
      ConfigFile.write_option(property.to_sym, value)
    end

    def handle_delete_command(property)
<<<<<<< HEAD
=======
      if property.nil?
        Uffizzi.ui.say('No property provided')
        return
      end
>>>>>>> fixes after rebase
      ConfigFile.delete_option(property.to_sym)
    end
  end
end
