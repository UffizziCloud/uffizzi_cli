# frozen_string_literal: true

require 'test_helper'

class DisconnectTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new

    sign_in
    @account_id = Uffizzi::ConfigFile.read_option(:account_id)
  end

  def test_disconnect_docker_hub_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id, Uffizzi.configuration.credential_types[:dockerhub])

    @cli.disconnect('docker-hub')

    assert_equal('Successfully disconnected from DockerHub.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_docker_registry_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id,
                                                                       Uffizzi.configuration.credential_types[:docker_registry])

    @cli.disconnect('docker-registry')

    assert_equal('Successfully disconnected from Docker Registry.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_github_registry_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id,
                                                                       Uffizzi.configuration.credential_types[:github_registry])

    @cli.disconnect('ghcr')

    assert_equal('Successfully disconnected from GHCR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_azure_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id, Uffizzi.configuration.credential_types[:azure])

    @cli.disconnect('acr')

    assert_equal('Successfully disconnected from ACR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_amazon_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id, Uffizzi.configuration.credential_types[:amazon])

    @cli.disconnect('ecr')

    assert_equal('Successfully disconnected from ECR.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_delete_credential)
  end

  def test_disconnect_google_success
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential(@account_id, Uffizzi.configuration.credential_types[:google])

    @cli.disconnect('gcr')

    assert_equal('Successfully disconnected from GCR.', Uffizzi.ui.last_message)
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
    body = json_fixture('files/uffizzi/credentials/delete_credential_failed.json')
    stubbed_uffizzi_delete_credential = stub_uffizzi_delete_credential_fail(@account_id, body,
                                                                            Uffizzi.configuration.credential_types[:dockerhub])

    error = assert_raises(Uffizzi::Error) do
      @cli.disconnect('docker-hub')
    end

    expected_error_message = render_error(body[:errors][:title].first)

    assert_equal(expected_error_message, error.message.strip)
    assert_requested(stubbed_uffizzi_delete_credential)
  end
end
