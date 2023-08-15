# frozen_string_literal: true

require 'test_helper'

class LogoutTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new
    sign_in
  end

  def test_logout_success
    Uffizzi::ConfigFile.write_option(:project, 'default')
    assert(Uffizzi::ConfigFile.option_has_value?(:cookie))
    assert(Uffizzi::ConfigFile.option_has_value?(:account))
    assert(Uffizzi::ConfigFile.option_has_value?(:project))

    stubbed_uffizzi_logout = stub_uffizzi_logout

    @cli.logout

    assert_requested(stubbed_uffizzi_logout)

    refute(Uffizzi::ConfigFile.option_has_value?(:cookie))
    refute(Uffizzi::ConfigFile.option_has_value?(:account))
    refute(Uffizzi::ConfigFile.option_has_value?(:project))
  end

  def test_logout_when_not_logged_in
    sign_out

    stubbed_uffizzi_logout = stub_uffizzi_logout

    @cli.logout

    assert_not_requested(stubbed_uffizzi_logout)
  end
end
