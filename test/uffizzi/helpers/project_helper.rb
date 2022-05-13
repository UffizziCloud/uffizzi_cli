# frozen_string_literal: true

module Uffizzi
  module ProjectHelper
    SLUG_ENDING_LENGTH = 6
    class << self
      def generate_slug(name)
        formatted_name = name.downcase.gsub(/ /, '-').gsub(/[^\w-]+/, '')
        slug_ending = generate_random_string(SLUG_ENDING_LENGTH)

        "#{formatted_name}-#{slug_ending}"
      end

      private

      def generate_random_string(length)
        hexatridecimal_base = 36
        rand(hexatridecimal_base**length).to_s(hexatridecimal_base)
      end
    end
  end
end
