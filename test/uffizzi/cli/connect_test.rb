# frozen_string_literal: true

require 'test_helper'

class ConnectTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli::Connect.new
    sign_in
  end

  def test_list_credentials
    body = json_fixture('files/uffizzi/credentials/uffizzi_credentials_list.json')
    stubbed_credentials_list = stub_uffizzi_list_credentials(body)

    @cli.list_credentials

    assert_requested(stubbed_credentials_list)
  end

  def test_connect_docker_hub_success
    body = json_fixture('files/uffizzi/credentials/uffizzi_dockerhub_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:dockerhub])

    credential_params = {
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    @cli.docker_hub

    assert_equal('Successfully connected to DockerHub', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_azure_success
    body = json_fixture('files/uffizzi/credentials/uffizzi_azure_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:azure])

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

    @cli.acr

    assert_equal('Successfully connected to ACR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_amazon_success
    body = json_fixture('files/uffizzi/credentials/uffizzi_amazon_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:amazon])

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

    @cli.ecr

    assert_equal('Successfully connected to ECR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_google_success
    body = json_fixture('files/uffizzi/credentials/uffizzi_google_credential.json')
    credential_path = "#{Dir.pwd}/test/fixtures/files/google/service-account.json"

    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:google])

    @cli.gcr(credential_path)

    assert_equal('Successfully connected to GCR', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_credential_failed
    body = json_fixture('files/uffizzi/credentials/uffizzi_credential_failed.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential_fail(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:dockerhub])

    credential_params = {
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    error = assert_raises(Uffizzi::Error) do
      @cli.docker_hub
    end

    assert_equal(body[:errors][:username].first, error.message.strip)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_credential_duplicate
    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:dockerhub])

    assert_raises(Uffizzi::Error) do
      @cli.docker_hub
    end

    assert_requested(stubbed_check_credential)
  end
end
