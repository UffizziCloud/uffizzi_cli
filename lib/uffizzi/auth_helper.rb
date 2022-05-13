# frozen_string_literal: true

module Uffizzi
  module AuthHelper
    class << self
      def signed_in?
        ConfigFile.exists? &&
          ConfigFile.option_has_value?(:account_id) &&
          ConfigFile.option_has_value?(:cookie) &&
          ConfigFile.option_has_value?(:server)
      end
    end
  end
end
