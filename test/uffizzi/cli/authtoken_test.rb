# frozen_string_literal: true

require 'test_helper'

class AuthtokenTest < Minitest::Test
  def setup
    @authtoken = Uffizzi::CLI::Authtoken.new

    @authtoken.options = { server: Uffizzi.configuration.server }
  end

  def test_authtoken_create_success
    body = json_fixture('files/uffizzi/uffizzi_authtoken_create_success.json')
    stubbed_uffizzi_create_token = stub_uffizzi_create_token(body)

    @authtoken.create

    assert_requested(stubbed_uffizzi_create_token)
    assert_equal(body[:docker_extension_auth_token][:code], Uffizzi.ui.last_message)
  end

  def test_authtoken_show_success
    body = json_fixture('files/uffizzi/uffizzi_authtoken_show_success.json')
    authtoken_code = body[:docker_extension_auth_token][:code]
    stubbed_uffizzi_show_token = stub_uffizzi_show_token(body, authtoken_code)

    @authtoken.show(authtoken_code)

    assert_requested(stubbed_uffizzi_show_token)
    assert_equal(body[:docker_extension_auth_token], Uffizzi.ui.last_message)
  end
end
