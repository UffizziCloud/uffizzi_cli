# frozen_string_literal: true

require 'test_helper'

class LogoutTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new
    sign_in
  end

  def test_logout_success
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
    stubbed_uffizzi_logout = stub_uffizzi_logout(headers)
    assert(Uffizzi::ConfigFile.exists?)

    buffer = StringIO.new
    $stdout = buffer

    @cli.logout

    $stdout = STDOUT

    assert_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.exists?)
  end

  def test_logout_when_not_logged_in
    Uffizzi::ConfigFile.delete
    refute(Uffizzi::ConfigFile.exists?)

    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
    stubbed_uffizzi_logout = stub_uffizzi_logout(headers)

    buffer = StringIO.new
    $stdout = buffer

    @cli.logout

    $stdout = STDOUT

    assert_not_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.exists?)
  end
end
