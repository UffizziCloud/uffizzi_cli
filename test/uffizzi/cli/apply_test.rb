# frozen_string_literal: true

require 'test_helper'

class ApplyTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
  end

  def test_apply_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {})
    body = json_fixture('files/uffizzi/uffizzi_create_deployment_success.json')
    stubbed_uffizzi_create_deployment = stub_uffizzi_create_deployment(Uffizzi.configuration.hostname, 201, body, {})

    @cli.options = { file: 'test/compose_files/test_compose_success.yml' }
    @cli.apply

    assert_equal('deployment created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_deployment)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_apply_invalid_compose
    body = json_fixture('files/uffizzi/uffizzi_create_compose_without_images.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 422, body, {})

    error_message = body[:errors][:path].last

    @cli.options = { file: 'test/compose_files/test_compose_without_images.yml' }
    @cli.apply

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_apply_invalid_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {})
    @cli.options = { file: 'test/compose_files/test_compose_with_invalid_env_path.yml' }

    assert_raises(Errno::ENOENT) do
      @cli.apply
    end

    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_apply_empty_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {})
    @cli.options = { file: 'test/compose_files/test_compose_with_empty_env_path.yml' }

    assert_raises(TypeError) do
      @cli.apply
    end

    assert_equal('env_file contains an empty value', Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_create_compose)
  end
end
