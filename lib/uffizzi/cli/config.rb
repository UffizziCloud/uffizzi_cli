# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class CLI::Config < Thor
    include ApiClient

    desc 'uffizzi config list', 'list'
    def list
      run('list')
    end

    desc 'uffizzi config get [PROPERTY]', 'get'
    def get(property)
      run('get', property)
    end

    desc 'uffizzi config set [PROPERTY] [VALUE]', 'set'
    def set(property, value)
      run('set', property, value)
    end

    desc 'uffizzi config delete [PROPERTY]', 'delete'
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
      end
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
    end

    def handle_delete_command(property)
      ConfigFile.delete_option(property.to_sym)
    end
  end
end
