# frozen_string_literal: true

require 'test_helper'

class ConsoleMock
  def getpass; end
end

class LoginTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    @command_params = {
      user: generate(:email),
      password: generate(:string),
      hostname: Uffizzi.configuration.hostname,
    }

    @cli.options = { user: @command_params[:user], hostname: @command_params[:hostname] }
  end

  def test_login_success
    console_mock = mock('console_mock')
    console_mock.stubs(:getpass).returns(@command_params[:password])
    IO.stubs(:console).returns(console_mock)

    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login(@command_params[:hostname], 201, body, headers)

    refute(Uffizzi::ConfigFile.exists?)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert(Uffizzi::ConfigFile.exists?)
  end

  def test_login_failed
    console_mock = mock('console_mock')
    console_mock.stubs(:getpass).returns(@command_params[:password])
    IO.stubs(:console).returns(console_mock)

    body = json_fixture('files/uffizzi/uffizzi_login_failed.json')
    stubbed_uffizzi_login = stub_uffizzi_login(@command_params[:hostname], 422, body, {})

    buffer = StringIO.new
    $stdout = buffer

    refute(Uffizzi::ConfigFile.exists?)

    @cli.login

    $stdout = STDOUT

    assert_requested(stubbed_uffizzi_login)
    refute(Uffizzi::ConfigFile.exists?)
  end
end
