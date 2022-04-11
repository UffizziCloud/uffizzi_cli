# frozen_string_literal: true

require 'test_helper'

class LoginTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new

    @command_params = {
      username: generate(:email),
      password: generate(:string),
      server: Uffizzi.configuration.server,
    }
  end

  def test_login_success_with_options_provided
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login_success(body)

    refute(Uffizzi::ConfigFile.exists?)

    @cli.options = { username: @command_params[:username], server: @command_params[:server] }

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert(Uffizzi::ConfigFile.exists?)
  end

  def test_login_success_with_options_from_config
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login_success(body)

    Uffizzi::ConfigFile.write_option(:server, Uffizzi.configuration.server)
    Uffizzi::ConfigFile.write_option(:username, @command_params[:username])

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert_equal(Uffizzi.configuration.server, @command_params[:server])
    assert_equal(@command_params[:username], Uffizzi::ConfigFile.read_option(:username))
  end

  def test_login_success_without_username
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login_success(body)

    refute(Uffizzi::ConfigFile.exists?)

    @cli.options = { server: @command_params[:server] }

    @cli.login

    assert_requested(stubbed_uffizzi_login)
  end

  def test_login_failed
    body = json_fixture('files/uffizzi/uffizzi_login_failed.json')
    stubbed_uffizzi_login = stub_uffizzi_login_failed(body)

    refute(Uffizzi::ConfigFile.exists?)

    @cli.options = { username: @command_params[:username], server: @command_params[:server] }

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    refute(Uffizzi::ConfigFile.exists?)
  end
end
