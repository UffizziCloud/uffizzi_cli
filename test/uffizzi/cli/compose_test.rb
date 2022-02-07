# frozen_string_literal: true

require 'test_helper'

class ComposeTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
  end

  def test_compose_add_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)

    @cli.options = { file: 'test/compose_files/test_compose_success.yml' }
    @cli.compose('add')

    assert_equal('compose file created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_add_with_invalid_compose
    body = json_fixture('files/uffizzi/uffizzi_create_compose_without_images.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:path].last

    @cli.options = { file: 'test/compose_files/test_compose_without_images.yml' }
    @cli.compose('add')

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_add_with_invalid_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)
    @cli.options = { file: 'test/compose_files/test_compose_with_invalid_env_path.yml' }

    assert_raises(Errno::ENOENT) do
      @cli.compose('add')
    end

    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_add_with_empty_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)
    @cli.options = { file: 'test/compose_files/test_compose_with_empty_env_path.yml' }

    assert_raises(TypeError) do
      @cli.compose('add')
    end

    assert_equal('env_file contains an empty value', Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_add_with_already_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_with_already_existed_compose_file.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:compose_file].last

    @cli.options = { file: 'test/compose_files/test_compose_success.yml' }
    @cli.compose('add')

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_remove_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_remove_compose = stub_uffizzi_remove_compose(Uffizzi.configuration.hostname, 204, body, {}, @project_slug)

    @cli.compose('remove')

    assert_equal('compose file deleted', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_remove_compose)
  end

  def test_compose_remove_with_not_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_compose_with_not_existed_compose_file.json')
    stubbed_uffizzi_remove_compose = stub_uffizzi_remove_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:compose_file].last

    @cli.compose('remove')

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_remove_compose)
  end

  def test_compose_describe_success
    body = json_fixture('files/uffizzi/uffizzi_describe_compose_success.json')
    stubbed_uffizzi_describe_compose = stub_uffizzi_describe_compose(Uffizzi.configuration.hostname, 200, body, {}, @project_slug)

    @cli.compose('describe')

    assert_requested(stubbed_uffizzi_describe_compose)
  end

  def test_compose_describe_with_not_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_compose_with_not_existed_compose_file.json')
    stubbed_uffizzi_describe_compose = stub_uffizzi_describe_compose(Uffizzi.configuration.hostname, 404, body, {}, @project_slug)

    error = assert_raises(StandardError) do
      @cli.compose('describe')
    end

    assert_equal("Not found", error.message)
    assert_requested(stubbed_uffizzi_describe_compose)
  end
end
