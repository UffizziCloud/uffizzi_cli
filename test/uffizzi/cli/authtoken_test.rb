# frozen_string_literal: true

require 'test_helper'

class AuthtokenTest < Minitest::Test
  def setup
    @authtoken = Uffizzi::CLI::Authtoken.new

    @authtoken.options = { server: Uffizzi.configuration.hostname }
  end

  def test_authtoken_create_success
    body = json_fixture('files/uffizzi/uffizzi_generate_token_success.json')
    stubbed_uffizzi_generate_token = stub_uffizzi_generate_token(body)

    @authtoken.create

    assert_requested(stubbed_uffizzi_generate_token)
    assert_equal(body[:docker_extension_auth_token][:code], Uffizzi.ui.last_message)
  end
end
