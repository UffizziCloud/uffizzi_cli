# frozen_string_literal: true

require 'awesome_print'

module Uffizzi
  module UI
    class Shell
      attr_accessor :output_format

      PRETTY_JSON = 'pretty-json'
      REGULAR_JSON = 'json'

      def initialize
        @shell = Thor::Shell::Basic.new
      end

      def say(message)
        formatted_message = case output_format
                            when PRETTY_JSON
                              format_to_pretty_json(message)
                            when REGULAR_JSON
                              format_to_json(message)
                            else
                              message
        end
        @shell.say(formatted_message)
      end

      def print_in_columns(messages)
        @shell.print_in_columns(messages)
      end

      def print_table(table_data)
        @shell.print_table(table_data)
      end

      def ask(message, *args)
        answer = @shell.ask(message, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        say("\n") unless options.fetch(:echo, true)
        answer
      end

      def last_message
        @shell.send(:stdout).string.strip
      end

      def disable_stdout
        $stdout = StringIO.new
      end

      def enable_stdout
        $stdout = IO.new(1, 'w')
      end

      private

      def format_to_json(data)
        data.to_json
      end

      def format_to_pretty_json(data)
        JSON.pretty_generate(data)
      end
    end
  end
end
