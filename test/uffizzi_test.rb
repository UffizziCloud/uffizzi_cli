# frozen_string_literal: true

require 'test_helper'
require 'uffizzi/cli'
require 'net/http'

class UffizziTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil(::Uffizzi::VERSION)
  end

  def test_login_success
    cli = Uffizzi::CLI.new
    command_params = {
      user: 'test@email.com',
      password: 'test_pass',
      hostname: 'http://web:7000/api/cli/v1/session',
    }

    cli.options = { user: command_params[:user], hostname: command_params[:hostname] }

    IO::console.stub(:getpass, command_params[:password]) do
      success_login_data = json_fixture('files/uffizzi/uffizzi_login_success.json')
      body = { user: { email: command_params[:user], password: command_params[:password] } }.to_json
      stubbed_uffizzi_login = stub_uffizzi_login(command_params[:hostname], body, success_login_data)

      File.delete(Uffizzi::CONFIG_PATH) if File.exist?(Uffizzi::CONFIG_PATH)

      cli.login

      assert_requested(stubbed_uffizzi_login)
      assert(File.exist?(Uffizzi::CONFIG_PATH))
    end
  end

  def test_login_failed
    cli = Uffizzi::CLI.new
    command_params = {
      user: 'test@email.com',
      password: 'test_pass',
      hostname: 'http://web:7000/api/cli/v1/session',
    }

    cli.options = { user: command_params[:user], hostname: command_params[:hostname] }

    IO::console.stub(:getpass, command_params[:password]) do
      failed_login_data = json_fixture('files/uffizzi/uffizzi_login_failed.json')
      body = { user: { email: command_params[:user], password: command_params[:password] } }.to_json
      stubbed_uffizzi_login = stub_uffizzi_login(command_params[:hostname], body, failed_login_data)

      File.delete(Uffizzi::CONFIG_PATH) if File.exist?(Uffizzi::CONFIG_PATH)

      cli.login

      assert_requested(stubbed_uffizzi_login)
      refute(File.exist?(Uffizzi::CONFIG_PATH))
    end
  end
end
