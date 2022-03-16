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

  def test_connect_azure_success
    body = json_fixture('files/uffizzi/uffizzi_azure_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)

    credential_params = {
      registry_url: generate(:url),
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:registry_url], credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    @cli.connect('acr')

    assert_equal('Successfully connected to ACR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
  end

  def test_connect_amazon_success
    body = json_fixture('files/uffizzi/uffizzi_amazon_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)

    credential_params = {
      registry_url: generate(:url),
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:registry_url], credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    @cli.connect('ecr')

    assert_equal('Successfully connected to ECR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
  end

  def test_connect_google_success
    body = json_fixture('files/uffizzi/uffizzi_google_credential.json')
    credential_path = "#{Dir.pwd}/test/fixtures/files/google/service-account.json"

    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)

    @cli.connect('gcr', credential_path)

    assert_equal('Successfully connected to GCR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
  end

  def test_unknown_credential_type
    credential_type = generate(:string)

    @cli.connect(credential_type)

    assert_equal('Unsupported credential type.', Uffizzi.ui.last_message)
  end

  def test_connect_credential_failed
    body = json_fixture('files/uffizzi/uffizzi_credential_failed.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential_fail(body)

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

    assert_equal(body[:errors][:username].first, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
  end
end
