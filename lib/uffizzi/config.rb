# frozen_string_literal: true

require 'json'
require 'fileutils'

module Uffizzi
  class Config
    CONFIG_PATH = "#{Dir.home}/.uffizzi/config.json"

    class << self
      def write(body, cookie, hostname)
        file = create
        file.write(prepare_config_data(body, cookie, hostname))
        file.close
      end

      def delete
        File.delete(CONFIG_PATH) if exists?
      end

      def exists?
        File.exist?(CONFIG_PATH)
      end

      def read_option(option)
        data = read
        return nil if data.nil?

        data[option]
      end

      def option_exists?(option)
        data = read
        return false if data.nil?

        data.key?(option)
      end

      private

      def read
        JSON.parse(File.read(CONFIG_PATH), symbolize_names: true)
      rescue Errno::ENOENT => e
        puts e
      end

      def prepare_config_data(body, cookie, hostname)
        account_data = {
          id: body[:user][:accounts].first[:id],
        }
        data = {
          account: account_data,
          hostname: hostname,
          cookie: cookie,
        }

        data.to_json
      end

      def create
        dir = File.dirname(CONFIG_PATH)

        unless File.directory?(dir)
          FileUtils.mkdir_p(dir)
        end

        File.new(CONFIG_PATH, 'w')
      end
    end
  end
end
