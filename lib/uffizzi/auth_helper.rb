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

<<<<<<< HEAD
      def project_set?
        ConfigFile.exists? &&
          ConfigFile.option_exists?(:project)
=======
        Uffizzi.ui.say('You are not logged in.') unless logged_in

        logged_in
>>>>>>> fixes after rebase
      end
    end
  end
end
