# frozen_string_literal: true

module Uffizzi
  module AuthHelper
    class << self
      def signed_in?
        config_data_exists? && authorized?
      end

      def sign_out
        return unless Uffizzi::ConfigFile.exists?

        Uffizzi::ConfigFile.unset_option(:cookie)
        Uffizzi::ConfigFile.unset_option(:account)
        Uffizzi::ConfigFile.unset_option(:project)
        Uffizzi::Token.delete if Uffizzi::Token.exists?
      end

      def check_login(project_option)
        raise Uffizzi::Error.new('You are not logged in. Run `uffizzi login`.') unless signed_in?
        raise Uffizzi::Error.new('This command needs project to be set in config file') unless project_set?(project_option)
      end

      private

      def config_data_exists?
        ConfigFile.exists? &&
          ConfigFile.option_has_value?(:server) &&
          ConfigFile.option_has_value?(:account)
      end

      def authorized?
        ConfigFile.option_has_value?(:cookie) || Uffizzi::Token.exists?
      end

      def project_set?(project_option)
        !project_option.nil? || (Uffizzi::ConfigFile.exists? && Uffizzi::ConfigFile.option_has_value?(:project))
      end
    end
  end
end
