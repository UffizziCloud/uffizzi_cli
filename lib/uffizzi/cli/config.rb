# frozen_string_literal: true

require 'io/console'
require 'uffizzi'

module Uffizzi
  class Config
    include ApiClient

    def run(command, property, value)
      case command
      when "list"
        ConfigFile.list
      when "get"
        if property.nil?
          puts "No property provided"
          return
        end
        option = ConfigFile.read_option(property.to_sym)
        puts option unless option.nil?
      when "set"
        if property.nil? || value.nil?
          puts "No property provided" if property.nil?
          puts "No value provided" if value.nil?
          return
        end
        ConfigFile.write_option(property.to_sym, value)
      when "delete"
        if property.nil?
          puts "No property provided"
          return
        end
        ConfigFile.delete_option(property.to_sym)
      end
    end
  end
end
