# frozen_string_literal: true

module Uffizzi
  module AuthHelper
    class << self
      def signed_in?
        config_data_exists? || Uffizzi::Token.exists?
      end

      def sign_out
        Uffizzi::ConfigFile.unset_option(:cookie)
        Uffizzi::ConfigFile.unset_option(:account)
        Uffizzi::ConfigFile.unset_option(:project)
        Uffizzi::Token.delete if Uffizzi::Token.exists?
      end

      private

      def config_data_exists?
        ConfigFile.exists? &&
          ConfigFile.option_has_value?(:account) &&
          ConfigFile.option_has_value?(:cookie) &&
          ConfigFile.option_has_value?(:server)
      end
    end
  end
end
