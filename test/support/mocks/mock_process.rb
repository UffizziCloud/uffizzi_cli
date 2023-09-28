# frozen_string_literal: true

class MockProcess
  attr_accessor :pid

  def initialize
    @pid = generate_pid
  end

  def kill(sig, pid)
    return @pid if sig.zero? && pid == @pid
    raise Errno::ESRCH if pid != @pid

    @pid = nil
  end

  def daemon
    @pid = generate_pid
  end

  private

  def generate_pid
    (Time.now.utc.to_f * 100_000).to_i
  end
end
