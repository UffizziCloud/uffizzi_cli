# frozen_string_literal: true

module Uffizzi
  class Error < Thor::Error; end

  def initialize(message)
    super("CLI Error: #{message}")
  end
end
