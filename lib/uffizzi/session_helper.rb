# frozen_string_literal: true

module Uffizzi
  module SessionHelper
    class << self
      def logged_in?
        logged_in = ConfigFile.exists? &&
        ConfigFile.option_exists?(:account_id) &&
        ConfigFile.option_exists?(:cookie) &&
        ConfigFile.option_exists?(:hostname)

        puts "You are not logged in." unless logged_in

        logged_in
      end
    end
  end
end
