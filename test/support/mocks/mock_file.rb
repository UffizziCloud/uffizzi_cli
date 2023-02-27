# frozen_string_literal: true

class MockFile
  class << self
    def open(_path, _option)
      f = new
      yield(f)

      f.strings
    end
  end

  def initialize
    @strings = []
  end

  def puts(string)
    @strings << string
  end

  def strings
    @strings.join("\n")
  end
end
