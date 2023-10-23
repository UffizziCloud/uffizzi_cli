# frozen_string_literal: true

class MockSignal
  class << self
    def trap(_sig); end
  end
end
