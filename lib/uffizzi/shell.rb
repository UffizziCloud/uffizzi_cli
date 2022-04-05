# frozen_string_literal: true

require 'thor'

module Uffizzi
  module UI
    class Shell
      attr_accessor :output_format

      def initialize
        @shell = Thor::Shell::Basic.new
      end

      def say(message)
        @shell.say(message)
      end

      def ask(msg, *args)
        @shell.ask(msg, *args)
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

      def disable_stdout
        $stdout = StringIO.new
      end

      def output(data)
        $stdout = IO.new(1, 'w')
        json_format? ? output_in_json(data) : output_in_github_format(data)
      end

      private

      def json_format?
        output_format == 'json'
      end

      def output_in_json(data)
        say(data.to_json)
      end

      def output_in_github_format(data)
        data.each_key do |key|
          say("::set-output name=#{key}::#{data[key]}")
        end
      end
    end
  end
end
