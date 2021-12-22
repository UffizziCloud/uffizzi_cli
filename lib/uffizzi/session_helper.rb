# frozen_string_literal: true

module Uffizzi
  module SessionHelper
    class << self
      def logged_in?
        logged_in = ConfigFile.exists? &&
        !ConfigFile.read_option(:account_id).nil? &&
        !ConfigFile.read_option(:cookie).nil? &&
        !ConfigFile.read_option(:hostname).nil?

        puts "You are not logged in." unless logged_in

        logged_in
      end
    end
  end
end
