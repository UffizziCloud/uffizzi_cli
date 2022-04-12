# frozen_string_literal: true

require 'test_helper'

class DisconnectTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new

    sign_in
  end

  def test_disconnect_docker_hub_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(Uffizzi.configuration.credential_types[:dockerhub])

    @cli.disconnect('docker-hub')

    assert_equal('Successfully disconnected DockerHub connection', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_github_container_registry_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(Uffizzi.configuration.credential_types[:github_container_registry])

    @cli.disconnect('ghcr')

    assert_equal('Successfully disconnected GHCR connection', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_azure_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(Uffizzi.configuration.credential_types[:azure])

    @cli.disconnect('acr')

    assert_equal('Successfully disconnected ACR connection', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_amazon_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(Uffizzi.configuration.credential_types[:amazon])

    @cli.disconnect('ecr')

    assert_equal('Successfully disconnected ECR connection', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_google_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(Uffizzi.configuration.credential_types[:google])

    @cli.disconnect('gcr')

    assert_equal('Successfully disconnected GCR connection', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_unknown_credential_type
    credential_type = generate(:string)

    error = assert_raises(Uffizzi::Error) do
      @cli.disconnect(credential_type)
    end

    assert_equal('Unsupported credential type.', error.message)
  end

  def test_disconnect_credential_failed
    body = json_fixture('files/uffizzi/credentials/uffizzi_delete_credential_failed.json')
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential_fail(body, Uffizzi.configuration.credential_types[:dockerhub])

    @cli.disconnect('docker-hub')

    assert_equal(body[:errors][:title].first, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end
end
