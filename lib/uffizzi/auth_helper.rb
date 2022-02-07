# frozen_string_literal: true

module Uffizzi
  module AuthHelper
    class << self
      def signed_in?
        ConfigFile.exists? &&
          ConfigFile.option_exists?(:account_id) &&
          ConfigFile.option_exists?(:cookie) &&
          ConfigFile.option_exists?(:hostname)
      end

      def project_set?
        ConfigFile.exists? &&
          ConfigFile.option_exists?(:project)
      end

      def project_set?
        project_set = ConfigFile.exists? &&
          ConfigFile.option_exists?(:project)

        Uffizzi.ui.say('This command needs project to be set in config file') unless project_set

        project_set
      end
    end
  end
end
