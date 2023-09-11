# frozen_string_literal: true

require 'uffizzi/helpers/config_helper'

module Uffizzi
  module LoginHelper
    class << self
      def prepare_request_params(username, password)
        {
          user: {
            email: username,
            password: password,
          },
        }
      end

      def set_server(options)
        config_server = ConfigFile.exists? ? Uffizzi::ConfigHelper.read_option_from_config(:server) : nil
        server_address = options[:server] || config_server || Uffizzi.configuration.default_server.to_s
        server_address.start_with?('http:', 'https:') ? server_address : "https://#{server_address}"
      end

      def set_username(options)
        config_username = ConfigFile.exists? ? Uffizzi::ConfigHelper.read_option_from_config(:username) : nil
        options_username = options[:email].present? ? options[:email] : nil
        options_username || config_username || Uffizzi.ui.ask('Username:')
      end

      def set_password
        ENV['UFFIZZI_PASSWORD'] || Uffizzi.ui.ask('Password:', echo: false)
      end
    end
  end
end
