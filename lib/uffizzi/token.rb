# frozen_string_literal: true

require 'json'
require 'uffizzi/helpers/file_helper'

module Uffizzi
  class Token
    TOKEN_PATH = "#{Dir.home}/.config/uffizzi/token"

    class << self
      def token_path
        TOKEN_PATH
      end

      def delete
        File.truncate(token_path, 0) if exists?
      end

      def exists?
        File.exist?(token_path) && !read.nil?
      end

      def read
        content = File.read(token_path)
        content.presence
      rescue Errno::ENOENT
        nil
      end

      def write(token)
        return nil unless token.is_a?(String)

        Uffizzi::FileHelper.write_with_lock(token_path, token)
      end
    end
  end
end
