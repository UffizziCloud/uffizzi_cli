# frozen_string_literal: true

require 'thor'

module Uffizzi
  module UI
    class Shell
      def initialize
        @shell = Thor::Shell::Basic.new
      end

      def say(msg)
        @shell.say(msg)
      end

      def last_message
        @shell.send(:stdout).string.strip
      end
    end
  end
end
