# frozen_string_literal: true

require 'test_helper'
require 'uffizzi/cli'

class UffizziTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil(::Uffizzi::VERSION)
  end

  def test_login
    cli = Uffizzi::CLI.new
    command_params = {
      user: 'test@email.com',
      password: 'test_pass',
      hostname: 'localhost'
    }
    cli.options = { user: command_params[:user], hostname: command_params[:hostname] }
    IO::console.stub(:getpass, command_params[:password]) do
      responce = cli.login
      assert_equal responce, command_params
    end
  end
end
