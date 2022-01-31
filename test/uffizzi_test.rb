# frozen_string_literal: true

require 'test_helper'
require 'uffizzi/cli'
require 'net/http'
require 'uffizzi/config'
require 'io/console'
require 'factory_bot'

class UffizziTest < Minitest::Test
  include FactoryBot::Syntax::Methods
  FactoryBot.find_definitions

  def test_that_it_has_a_version_number
    refute_nil(::Uffizzi::VERSION)
  end

  def test_login_success
    cli = Uffizzi::CLI.new

    command_params = {
      user: generate(:email),
      password: generate(:string),
      hostname: 'http://web:7000',
    }

    cli.options = { user: command_params[:user], hostname: command_params[:hostname] }

    IO::console.stub(:getpass, command_params[:password]) do
      headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }
      body = json_fixture('files/uffizzi/uffizzi_login_success.json')[:body]

      stubbed_uffizzi_login = stub_uffizzi_login(command_params[:hostname], 201, body, headers)

      Uffizzi::Config.delete

      cli.login

      assert_requested(stubbed_uffizzi_login)
      assert(Uffizzi::Config.exists?)
    end
  end

  def test_login_failed
    cli = Uffizzi::CLI.new
    command_params = {
      user: generate(:email),
      password: generate(:string),
      hostname: 'http://web:7000',
    }

    cli.options = { user: command_params[:user], hostname: command_params[:hostname] }

    IO::console.stub(:getpass, command_params[:password]) do
      body = json_fixture('files/uffizzi/uffizzi_login_failed.json')[:body]
      stubbed_uffizzi_login = stub_uffizzi_login(command_params[:hostname], 422, body, {})

      Uffizzi::Config.delete

      cli.login

      assert_requested(stubbed_uffizzi_login)
      refute(Uffizzi::Config.exists?)
    end
  end
end
