# frozen_string_literal: true

module Uffizzi
  module ConfigHelper
    class << self
      def read_option_from_config(option)
        ConfigFile.option_has_value?(option) ? ConfigFile.read_option(option) : nil
      end

      def account_config(id, name = nil)
        { id: id, name: name }
      end
    end
  end
end
