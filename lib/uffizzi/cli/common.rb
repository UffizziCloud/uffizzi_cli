# frozen_string_literal: true

module Uffizzi
  class Cli::Common
    class << self
      def show_manual(command_name)
        puts "show manual start"
        manual_doc_path = File.join(Uffizzi.root, "man/#{command_name}.ronn")
        puts "found manual_doc_path"

        Uffizzi.ui.say(File.read(manual_doc_path))
      end
    end
  end
end
