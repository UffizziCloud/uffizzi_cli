# frozen_string_literal: true

require 'awesome_print'
require 'open3'

module Uffizzi
  module UI
    class Shell
      class ExitError < Thor::Error; end
      attr_accessor :output_format

      PRETTY_JSON = 'pretty-json'
      REGULAR_JSON = 'json'
      PRETTY_LIST = 'pretty-list'

      def initialize
        @shell = Thor::Shell::Basic.new
      end

      def say(message)
        @shell.say(format_message(message))
      end

      def say_error_and_exit(message)
        raise ExitError.new(format_message(message))
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

      def stdout_pipe?
        $stdout.stat.pipe?
      end

      def popen(command)
        IO.popen(command)
      end

      def popen2e(command, &block)
        Open3.popen2e(command, &block)
      end

      def capture3(command)
        Open3.capture3(command)
      end

      private

      def format_to_json(data)
        data.to_json
      end

      def format_to_pretty_json(data)
        JSON.pretty_generate(data)
      end

      def format_to_pretty_list(data)
        case data
        when Array
          data.map { |v| format_to_pretty_list(v) }.join("\n\n")
        when Hash
          data.map { |k, v| "- #{k.to_s.capitalize.gsub('_', ' ')}: #{v}" }.join("\n").strip
        else
          data
        end
      end

      def format_message(message)
        case output_format
        when PRETTY_JSON
          format_to_pretty_json(message)
        when REGULAR_JSON
          format_to_json(message)
        when PRETTY_LIST
          format_to_pretty_list(message)
        else
          message
        end
      end
    end
  end
end
