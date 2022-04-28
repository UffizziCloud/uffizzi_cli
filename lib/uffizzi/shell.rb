# frozen_string_literal: true

require 'awesome_print'

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

      def pretty_say(collection, index = true)
        ap(collection, { index: index })
      end

      def disable_stdout
        $stdout = StringIO.new
      end

      def output(data)
        $stdout = IO.new(1, 'w')
        json_format? ? output_in_json(data) : output_in_github_format(data)
      end

      def describe_project(project)
        json_format? ? output_in_json(project) : output_in_pretty_format(project)
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

      def output_in_pretty_format(project)
        say("Project name: #{project[:name]}")
        say("Project slug: #{project[:slug]}")
        say("Description: #{project[:description]}".strip)
        say("Created: #{project[:created_at]}")
        say("Default compose: #{project[:default_compose][:source]}")
        say('Previews:')
        project[:deployments].each do |deployment|
          say("  - deployment-#{deployment[:id]} (#{deployment[:subdomain]})")
        end
        say('Secrets:')
        project[:secrets].each do |secret|
          say("  - #{secret}")
        end
      end
    end
  end
end
