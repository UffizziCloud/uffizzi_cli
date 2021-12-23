# frozen_string_literal: true

require 'test_helper'

class LoginTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    @command_params = {
      user: generate(:email),
      password: generate(:string),
      hostname: 'http://web:7000',
    }

    @cli.options = { user: @command_params[:user], hostname: @command_params[:hostname] }
  end

  def test_login_success
    IO::console.stub(:getpass, @command_params[:password]) do
      headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
      body = json_fixture('files/uffizzi/uffizzi_login_success.json')

      stubbed_uffizzi_login = stub_uffizzi_login(@command_params[:hostname], 201, body, headers)

      Uffizzi::ConfigFile.delete

      @cli.login

      assert_requested(stubbed_uffizzi_login)
      assert(Uffizzi::ConfigFile.exists?)
    end
  end

  def test_login_failed
    IO::console.stub(:getpass, @command_params[:password]) do
      body = json_fixture('files/uffizzi/uffizzi_login_failed.json')
      stubbed_uffizzi_login = stub_uffizzi_login(@command_params[:hostname], 422, body, {})

      Uffizzi::ConfigFile.delete

      buffer = StringIO.new
      $stdout = buffer
      
      @cli.login

      $stdout = STDOUT

      assert_requested(stubbed_uffizzi_login)
      refute(Uffizzi::ConfigFile.exists?)
    end
  end
end
