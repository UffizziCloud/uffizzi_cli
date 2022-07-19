# frozen_string_literal: true

require 'test_helper'

class ConnectTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli::Connect.new
    sign_in
  end

  def test_list_credentials
    body = json_fixture('files/uffizzi/credentials/credentials_list.json')
    stubbed_credentials_list = stub_uffizzi_list_credentials(body)

    @cli.list_credentials

    assert_requested(stubbed_credentials_list)
  end

  def test_connect_docker_hub_success
    body = json_fixture('files/uffizzi/credentials/dockerhub_credential.json')
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

    assert_equal('Successfully connected to Docker Hub.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_docker_registry_success
    body = json_fixture('files/uffizzi/credentials/docker_registry_credentials.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:docker_registry])

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

    @cli.docker_registry

    assert_equal('Successfully connected to Docker Registry', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_azure_success
    body = json_fixture('files/uffizzi/credentials/azure_credential.json')
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

    assert_equal('Successfully connected to ACR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_amazon_success
    body = json_fixture('files/uffizzi/credentials/amazon_credential.json')
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

    assert_equal('Successfully connected to ECR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_google_success
    body = json_fixture('files/uffizzi/credentials/google_credential.json')
    credential_path = "#{Dir.pwd}/test/fixtures/files/google/service-account.json"

    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:google])

    @cli.gcr(credential_path)

    assert_equal('Successfully connected to GCR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_github_registry_success
    body = json_fixture('files/uffizzi/credentials/github_registry_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:github_registry])

    credential_params = {
      username: generate(:string),
      password: generate(:string),
    }

    console_mock = mock('console_mock')
    console_mock.stubs(:write)
    console_mock.stubs(:gets).returns(credential_params[:username])
    console_mock.stubs(:getpass).returns(credential_params[:password])
    IO.stubs(:console).returns(console_mock)

    @cli.ghcr

    assert_equal('Successfully connected to GHCR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_credential_failed
    body = json_fixture('files/uffizzi/credentials/credential_failed.json')
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

  def test_connect_docker_hub_with_skip_raise_existence_error_option
    @cli.options = command_options(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:dockerhub])

    assert_raises(SystemExit) do
      @cli.docker_hub
    end

    assert_equal('Credential of type docker-hub already exists for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_docker_registry_with_skip_raise_existence_error_option
    @cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:docker_registry])

    assert_raises(SystemExit) do
      @cli.docker_registry
    end

    assert_equal('Credentials of type docker-registry already exist for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_azure_with_skip_raise_existence_error_option
    @cli.options = command_options(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:azure])

    assert_raises(SystemExit) do
      @cli.acr
    end

    assert_equal('Credential of type acr already exists for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_amazon_with_skip_raise_existence_error_option
    @cli.options = command_options(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:amazon])

    assert_raises(SystemExit) do
      @cli.ecr
    end

    assert_equal('Credential of type ecr already exists for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_google_with_skip_raise_existence_error_option
    @cli.options = command_options(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:google])

    assert_raises(SystemExit) do
      @cli.gcr
    end

    assert_equal('Credential of type gcr already exists for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_github_with_skip_raise_existence_error_option
    @cli.options = command_options(skip_raise_existence_error: true)

    stubbed_check_credential = stub_uffizzi_check_credential_fail(Uffizzi.configuration.credential_types[:github_registry])

    assert_raises(SystemExit) do
      @cli.ghcr
    end

    assert_equal('Credential of type ghcr already exists for this account.', Uffizzi.ui.last_message)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_docker_hub_with_env_variables
    ENV['DOCKERHUB_USERNAME'] = generate(:string)
    ENV['DOCKERHUB_PASSWORD'] = generate(:string)

    body = json_fixture('files/uffizzi/credentials/dockerhub_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:dockerhub])

    @cli.docker_hub

    assert_equal('Successfully connected to Docker Hub.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_docker_registry_with_env_variables
    ENV['DOCKER_REGISTRY_URL'] = generate(:url)
    ENV['DOCKER_REGISTRY_USERNAME'] = generate(:string)
    ENV['DOCKER_REGISTRY_PASSWORD'] = generate(:string)

    body = json_fixture('files/uffizzi/credentials/docker_registry_credentials.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:docker_registry])

    @cli.docker_registry

    assert_equal('Successfully connected to Docker Registry', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_azure_with_env_variables
    ENV['ACR_USERNAME'] = generate(:string)
    ENV['ACR_PASSWORD'] = generate(:string)
    ENV['ACR_REGISTRY_URL'] = generate(:url)

    body = json_fixture('files/uffizzi/credentials/azure_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:azure])

    @cli.acr

    assert_equal('Successfully connected to ACR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_amazon_with_env_variables
    ENV['AWS_ACCESS_KEY_ID'] = generate(:string)
    ENV['AWS_SECRET_ACCESS_KEY'] = generate(:string)
    ENV['AWS_REGISTRY_URL'] = generate(:url)

    body = json_fixture('files/uffizzi/credentials/amazon_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:amazon])

    @cli.ecr

    assert_equal('Successfully connected to ECR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_google_with_env_variables
    ENV['GCLOUD_SERVICE_KEY'] = generate(:string)

    body = json_fixture('files/uffizzi/credentials/google_credential.json')

    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:google])

    @cli.gcr

    assert_equal('Successfully connected to GCR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_github_registry_with_env_variables
    ENV['GITHUB_USERNAME'] = generate(:string)
    ENV['GITHUB_ACCESS_TOKEN'] = generate(:string)

    body = json_fixture('files/uffizzi/credentials/github_registry_credential.json')
    stubbed_uffizzi_create_credential = stub_uffizzi_create_credential(body)
    stubbed_check_credential = stub_uffizzi_check_credential_success(Uffizzi.configuration.credential_types[:github_registry])

    @cli.ghcr

    assert_equal('Successfully connected to GHCR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_credential)
    assert_requested(stubbed_check_credential)
  end

  def test_connect_docker_hub_with_update_with_env_variables
    body = json_fixture('files/uffizzi/credentials/dockerhub_credential.json')
    stubbed_uffizzi_update_credential = stub_uffizzi_update_credential(body, body[:type])
    stubbed_check_credential_fail = stub_uffizzi_check_credential_fail(body[:type])

    ENV['DOCKERHUB_USERNAME'] = generate(:string)
    ENV['DOCKERHUB_PASSWORD'] = generate(:string)

    @cli.options = command_options(update_credential_if_exists: true)
    @cli.docker_hub

    assert_equal('Successfully connected to Docker Hub.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_update_credential)
    assert_requested(stubbed_check_credential_fail)
  end
end
