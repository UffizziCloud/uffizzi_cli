# frozen_string_literal: true

require 'open3'

module Uffizzi
  class Cli::Common
    class << self
      def show_manual(command_name)
        manual_doc_path = File.join(Uffizzi.root, "man/#{command_name}")

        Open3.pipeline("man #{manual_doc_path}")
      end
    end
  end
end
