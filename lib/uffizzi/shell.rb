# frozen_string_literal: true

require 'thor'

module Uffizzi
  module UI
    class Shell
      def initialize
        @shell = Thor::Shell::Basic.new
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
    end
  end
end
