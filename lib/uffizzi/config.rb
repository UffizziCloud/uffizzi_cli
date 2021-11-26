# frozen_string_literal: true

require 'json'
require 'fileutils'

module Uffizzi
  class Config
    CONFIG_PATH = "#{Dir.home}/.uffizzi/config.json"

    class << self
      def write(data)
        file = create
        file.write(data.to_json)
        file.close
      end

      def delete
        File.delete(CONFIG_PATH) if exists?
      end

      def read
        unless exists?
          puts "Config file doesn't exists"
          return nil
        end
        JSON.parse(File.read(CONFIG_PATH), symbolize_names: true)
      end

      def exists?
        File.exist?(CONFIG_PATH)
      end

      def read_option(option)
        data = read
        return nil if data.nil?

        data[option]
      end

      private

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
