# frozen_string_literal: true

require 'test_helper'

class ConnectTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    sign_in
  end

  def test_connect_docker_hub_success
    body = json_fixture('files/uffizzi/uffizzi_dockerhub_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)

    credential_params = {
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    @cli.connect('docker-hub')

    assert_equal('Successfully connected to DockerHub', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
  end
end
