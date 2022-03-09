# frozen_string_literal: true

require 'json'
require 'fileutils'

module Uffizzi
  class ConfigFile
    CONFIG_PATH = "#{Dir.home}/.uffizzi/config.json"

    class << self
      def create(account_id, cookie, hostname)
        data = prepare_config_data(account_id, cookie, hostname)
        data.each_pair { |key, value| write_option(key, value) }
      end

      def delete
        File.delete(CONFIG_PATH) if exists?
      end

      def exists?
        File.exist?(CONFIG_PATH)
      end

      def read_option(option)
        data = read
        return nil unless data.is_a?(Hash)

        data[option]
      end

      def option_exists?(option)
        data = read
        return false unless data.is_a?(Hash)

        data.key?(option)
      end

      def write_option(key, value)
        data = exists? ? read : {}
        return nil unless data.is_a?(Hash)

        data[key] = value
        write(data.to_json)
      end

      def delete_option(key)
        data = read
        return nil unless data.is_a?(Hash)

        new_data = data.except(key)
        write(new_data.to_json)
      end

      def rewrite_cookie(cookie)
        write_option(:cookie, cookie)
      end

      def list
        data = read
        return nil unless data.is_a?(Hash)

        content = data.reduce('') do |acc, pair|
          property, value = pair
          "#{acc}#{property} - #{value}\n"
        end

        Uffizzi.ui.say(content)

        data
      end

      private

      def read
        JSON.parse(File.read(CONFIG_PATH), symbolize_names: true)
      rescue Errno::ENOENT => e
        Uffizzi.ui.say(e)
      rescue JSON::ParserError
        Uffizzi.ui.say('Config file is in incorrect format')
      end

      def write(data)
        file = create_file
        file.write(data)
        file.close
      end

      def prepare_config_data(account_id, cookie, hostname)
        {
          account_id: account_id,
          hostname: hostname,
          cookie: cookie,
        }
      end

      def create_file
        dir = File.dirname(CONFIG_PATH)

        FileUtils.mkdir_p(dir) unless File.directory?(dir)

        File.new(CONFIG_PATH, 'w')
      end
    end
  end
end
