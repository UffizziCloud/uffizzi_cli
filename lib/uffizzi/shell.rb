# frozen_string_literal: true

require 'thor'

module Uffizzi
  module UI
    class Shell
      def initialize
        @shell = Thor::Shell::Color.new
      end

      def say(message)
        @shell.say(message)
      end

      def print_in_columns(messages)
        @shell.print_in_columns(messages)
      end

      def print_table(table_data)
        @shell.print_table(table_data)
      end

      def last_message
        @shell.send(:stdout).string.strip
      end

      def error(message)
        @shell.say(message, Thor::Shell::Color::RED)
      end

      def success(message)
        @shell.say(message, Thor::Shell::Color::GREEN)
      end
    end
  end
end
