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

      def output(outputed_object)
        $stdout = IO.new(1, 'w')
        output_format == 'json' ? output_in_json(outputed_object) : output_in_github_format(outputed_object)
      end

      def output_in_json(outputed_object)
        say(outputed_object.to_json)
      end

      def output_in_github_format(outputed_object)
        outputed_object.each_key do |key|
          say("::set-output name=#{key}::#{outputed_object[key]}")
        end
      end
    end
  end
end
