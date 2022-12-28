# frozen_string_literal: true

require 'test_helper'

class LoginByIdentityTokenTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new
    @cli.options = command_options(token: 'token', server: Uffizzi.configuration.server, access_token: 'token')
  end

  def test_login_success_with_oidc
    body = json_fixture('files/uffizzi/uffizzi_login_by_jwt_success.json')
    stubbed_uffizzi_login = stub_uffizzi_login_by_identity_token_success(body)

    refute(Uffizzi::ConfigFile.option_exists?(:server))
    refute(Uffizzi::ConfigFile.option_exists?(:username))

    @cli.login_by_identity_token

    assert_requested(stubbed_uffizzi_login)
    assert(Uffizzi::ConfigFile.option_exists?(:account_id))
    assert(Uffizzi::ConfigFile.option_exists?(:project))
  end

  def test_login_failed
    body = json_fixture('files/uffizzi/uffizzi_login_by_jwt_failure.json')
    stubbed_uffizzi_login = stub_uffizzi_login_by_identity_token_failure(body)

    assert_raises(Uffizzi::ServerResponseError) do
      @cli.login_by_identity_token
    end

    assert_requested(stubbed_uffizzi_login)
    refute(Uffizzi::ConfigFile.option_exists?(:account_id))
    refute(Uffizzi::ConfigFile.option_exists?(:project))
  end
end
