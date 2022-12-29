# frozen_string_literal: true

module Uffizzi
  RESPONSE_SERVER_ERROR_HEADER = "Server Error:\n"
  CLI_ERROR_HEADER = "CLI Error:\n"

  class Error < Thor::Error; end

  class ServerResponseError < Thor::Error
    def initialize(message)
      super("#{RESPONSE_SERVER_ERROR_HEADER}#{message}")
    end
  end

  class CliError < Thor::Error
    def initialize(message)
      super("#{CLI_ERROR_HEADER}#{message}")
    end
  end
end
