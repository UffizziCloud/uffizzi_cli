# frozen_string_literal: true

require 'tty-prompt'

module Uffizzi
  module UI
    class Prompt

      def initialize
        @prompt = TTY::Prompt.new
      end

      def select(question, choices)
        answer = @prompt.select(question, choices)
      end

      def ask(message, *args)
        answer = @prompt.ask(message, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        say("\n") unless options.fetch(:echo, true)
        answer
      end
    end
  end
end
