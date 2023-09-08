# frozen_string_literal: true

module Uffizzi
  class Cli::Common
    class << self
      def show_manual(command_name)
        manual_doc_path = File.join(Uffizzi.root, "share/man/#{command_name}.ronn")

        Uffizzi.ui.say(File.read(manual_doc_path))
      end
    end
  end
end
