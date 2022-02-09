# frozen_string_literal: true

require 'test_helper'

class LogoutTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new
    sign_in
  end

  def test_logout_success
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
    host_name = Uffizzi.configuration.hostname
    stubbed_uffizzi_logout = stub_uffizzi_logout(host_name, 204, headers)
    assert(Uffizzi::ConfigFile.exists?)

    @cli.logout

    assert_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.exists?)
  end

  def test_logout_when_not_logged_in
    Uffizzi::ConfigFile.delete
    refute(Uffizzi::ConfigFile.exists?)

    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
    host_name = Uffizzi.configuration.hostname
    stubbed_uffizzi_logout = stub_uffizzi_logout(host_name, 204, headers)

    @cli.logout

    assert_not_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.exists?)
  end
end
