# frozen_string_literal: true

require 'tty-prompt'

module Uffizzi
  module UI
    class Prompt
      def initialize
        @prompt = TTY::Prompt.new
      end

      def select(question, choices)
        @prompt.select(question, choices)
      end

      def ask(message, **args)
        @prompt.ask(message, **args)
      end

      def yes?(message)
        @prompt.yes?(message)
      end
    end
  end
end
