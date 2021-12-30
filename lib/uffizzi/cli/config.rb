# frozen_string_literal: true

require 'io/console'
require 'uffizzi'
require 'uffizzi/clients/api/api_client'

module Uffizzi
  class Config
    include ApiClient

    def run(command, property, value)
      case command
      when 'list'
        handle_list_command
      when 'get'
        handle_get_command(property)
      when 'set'
        handle_set_command(property, value)
      when 'delete'
        handle_delete_command(property)
      else
        Uffizzi.ui.say("#{command} is not a uffizzi config command")
      end
    end

    private

    def handle_list_command
      ConfigFile.list
    end

    def handle_get_command(property)
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
      ConfigFile.write_option(property.to_sym, value)
    end

    def handle_delete_command(property)
      if property.nil?
        Uffizzi.ui.say('No property provided')
        return
      end
      ConfigFile.delete_option(property.to_sym)
    end
  end
end
