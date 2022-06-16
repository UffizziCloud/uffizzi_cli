# frozen_string_literal: true

require 'json'
require 'fileutils'

module Uffizzi
  class ConfigFile
    CONFIG_PATH = "#{Dir.home}/.config/uffizzi/config_default"

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

      def option_exists?(option)
        data = read
        return false unless data.is_a?(Hash)

        data.key?(option)
      end

      private

      def read
        data = File.read(config_path)
        options = data.split("\n")
        options.reduce({}) do |acc, option|
          key, value = option.split('=', 2)
          acc.merge({ key.strip.to_sym => value.strip })
        end
      rescue Errno::ENOENT => e
        file_path = e.message.split(' ').last
        message = "Configuration file not found: #{file_path}\n" \
        'To configure the uffizzi CLI interactively, run $ uffizzi config'
        raise Uffizzi::Error.new(message)
      end

      def write(data)
        prepared_data = prepare_data(data)

        lock(config_path) { atomic_write(config_path, "#{config_path}.tmp", prepared_data) }
      end

      def prepare_data(data)
        data.reduce('') do |acc, option|
          key, value = option
          "#{acc}#{key} = #{value}\n"
        end
      end

      def atomic_write(path, temp_path, content)
        File.open(temp_path, 'w') { |f| f.write(content) }
        FileUtils.mv(temp_path, path)
      end

      def lock(path)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)

        File.open(path).flock(File::LOCK_EX) if File.exist?(path)
        yield
        File.open(path).flock(File::LOCK_UN)
      end
    end
  end
end
