# frozen_string_literal: true

module Uffizzi
  module FileHelper
    class << self
      def write_with_lock(path, data)
        lock(path) { atomic_write(path, "#{path}.tmp", data) }
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
