# frozen_string_literal: true

class MockLaunchy
  class << self
    def open(url)
      Uffizzi.ui.say(url)
    end
  end
end
