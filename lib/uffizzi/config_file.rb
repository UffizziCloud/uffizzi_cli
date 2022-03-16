# frozen_string_literal: true

require 'json'
require 'fileutils'

module Uffizzi
  class ConfigFile
    CONFIG_PATH = "#{Dir.home}/.config/uffizzi/config_default.json"

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

      def option_has_value?(option)
        data = read
        return false if !data.is_a?(Hash) || !option_exists?(option)

        !data[option].empty?
      end

      def write_option(key, value)
        data = exists? ? read : {}
        return nil unless data.is_a?(Hash)

        data[key] = value
        write(data)
      end

      def unset_option(key)
        data = read
        return nil unless data.is_a?(Hash) || !option_exists?(key)

        data[key] = ''
        write(data)
      end

      def rewrite_cookie(cookie)
        write_option(:cookie, cookie)
      end

      def list
        data = read
        return nil unless data.is_a?(Hash)

        content = data.reduce('') do |acc, pair|
          property, value = pair
          "#{acc}#{property} = #{value}\n"
        end

        Uffizzi.ui.say(content)

        data
      end

      private

      def option_exists?(option)
        data = read
        return false unless data.is_a?(Hash)

        data.key?(option)
      end

      def read
        data = File.read(CONFIG_PATH)
        options = data.split("\n")
        result = {}
        options.each do |option|
          key, value = option.split('=', 2)
          result[key.strip.to_sym] = value.strip
        end

        result
      rescue Errno::ENOENT => e
        Uffizzi.ui.say(e)
      end

      def write(data)
        file = create_file
        prepared_data = prepare_data(data)
        file.write(prepared_data)
        file.close
      end

      def prepare_data(data)
        result = ''
        data.each_key do |key|
          result = "#{result}#{key} = #{data[key]}\n"
        end

        result
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
