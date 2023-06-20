# frozen_string_literal: true

require 'json'
require 'uffizzi/helpers/file_helper'

module Uffizzi
  class ConfigFile
    CONFIG_PATH = "#{Dir.home}/.config/uffizzi/config_default.json"

    class << self
      def config_path
        CONFIG_PATH
      end

      def delete
        File.truncate(config_path, 0) if exists?
      end

      def exists?
        File.exist?(config_path)
      end

      def read_option(option, nested_option = nil)
        data = read

        value = data[option]
        return value.presence if nested_option.nil?
        return nil unless value.is_a?(Hash)

        value[nested_option].presence
      end

      def option_has_value?(option)
        data = read
        return false unless option_exists?(option)

        data[option].present?
      end

      def write_option(key, value)
        data = exists? ? read : {}

        data[key] = value
        write(data)
      end

      def unset_option(key)
        data = read
        return unless option_exists?(key)

        data[key] = ''
        write(data)
      end

      def rewrite_cookie(cookie)
        write_option(:cookie, cookie)
      end

      def list
        data = read

        content = data.reduce('') do |acc, pair|
          property, value = pair
          "#{acc}#{property} = #{value}\n"
        end

        Uffizzi.ui.say(content)

        data
      end

      def option_exists?(option)
        data = read

        data.key?(option)
      end

      private

      def read
        data = File.read(config_path)
        JSON.parse(data).deep_symbolize_keys
      rescue Errno::ENOENT => e
        file_path = e.message.split(' ').last
        message = "Configuration file not found: #{file_path}\n" \
        'To configure the uffizzi CLI interactively, run $ uffizzi config'
        raise Uffizzi::Error.new(message)
      rescue JSON::ParserError
        {}
      end

      def write(data)
        Uffizzi::FileHelper.write_with_lock(config_path, data.to_json)
      end
    end
  end
end
