# frozen_string_literal: true

require 'test_helper'

class ComposeTest < Minitest::Test
  def setup
    @compose = Uffizzi::CLI::Project::Compose.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
  end

  def test_compose_set_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)

    @compose.options = { file: 'test/compose_files/test_compose_success.yml' }
    @compose.set

    assert_equal('compose file created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_invalid_compose
    body = json_fixture('files/uffizzi/uffizzi_create_compose_without_images.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:path].last

    @compose.options = { file: 'test/compose_files/test_compose_without_images.yml' }
    @compose.set

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_invalid_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)
    @compose.options = { file: 'test/compose_files/test_compose_with_invalid_env_path.yml' }

    assert_raises(Errno::ENOENT) do
      @compose.set
    end

    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_empty_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 201, body, {}, @project_slug)
    @compose.options = { file: 'test/compose_files/test_compose_with_empty_env_path.yml' }

    assert_raises(TypeError) do
      @compose.set
    end

    assert_equal('env_file contains an empty value', Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_already_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_with_already_existed_compose_file.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:compose_file].last

    @compose.options = { file: 'test/compose_files/test_compose_success.yml' }
    @compose.set

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_unset_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_unset_compose(Uffizzi.configuration.hostname, 204, body, {}, @project_slug)

    @compose.unset

    assert_equal('compose file deleted', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_unset_with_not_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_compose_with_not_existed_compose_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_unset_compose(Uffizzi.configuration.hostname, 422, body, {}, @project_slug)

    error_message = body[:errors][:compose_file].last

    @compose.unset

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_describe_valid_file
    body = json_fixture('files/uffizzi/uffizzi_describe_compose_valid_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_describe_compose(Uffizzi.configuration.hostname, 200, body, {}, @project_slug)

    @compose.describe

    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_describe_invalid_file
    body = json_fixture('files/uffizzi/uffizzi_describe_compose_invalid_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_describe_compose(Uffizzi.configuration.hostname, 200, body, {}, @project_slug)

    error_message = body[:compose_file][:payload][:errors][:path].last

    @compose.describe

    assert_equal(error_message, Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_unset_compose)
  end
end
