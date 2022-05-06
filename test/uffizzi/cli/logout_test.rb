# frozen_string_literal: true

require 'test_helper'

class LogoutTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new
    sign_in
  end

  def test_logout_success
    stubbed_uffizzi_logout = stub_uffizzi_logout
    refute(Uffizzi::ConfigFile.option_exists?(:username))

    @cli.logout

    assert_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.option_exists?(:username))
    refute(Uffizzi::ConfigFile.option_exists?(:server))
  end

  def test_logout_when_not_logged_in
    Uffizzi::ConfigFile.delete
    refute(Uffizzi::ConfigFile.option_exists?(:username))
    refute(Uffizzi::ConfigFile.option_exists?(:server))

    stubbed_uffizzi_logout = stub_uffizzi_logout

    @cli.logout

    assert_not_requested(stubbed_uffizzi_logout)
    refute(Uffizzi::ConfigFile.option_exists?(:username))
    refute(Uffizzi::ConfigFile.option_exists?(:server))
  end
end
