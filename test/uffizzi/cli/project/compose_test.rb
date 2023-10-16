# frozen_string_literal: true

require 'test_helper'

class ComposeTest < Minitest::Test
  def setup
    @compose = Uffizzi::Cli::Project::Compose.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    ENV.delete('IMAGE')
    ENV.delete('CONFIG_SOURCE')
    ENV.delete('PORT')
  end

  def test_compose_set_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)

    @compose.options = command_options(file: 'test/compose_files/test_compose_success.yml')
    @compose.set

    assert_equal('compose file created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_env_vars_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    ENV['IMAGE'] = 'nginx'
    ENV['CONFIG_SOURCE'] = 'vote.conf'
    ENV['PORT'] = '80'

    @compose.options = command_options(file: 'test/compose_files/test_compose_with_env_vars.yml')
    @compose.set

    assert_equal('compose file created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_env_vars_failed
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    ENV['IMAGE'] = 'nginx'
    ENV['CONFIG_SOURCE'] = 'vote.conf'

    @compose.options = command_options(file: 'test/compose_files/test_compose_with_env_vars.yml')
    error = assert_raises(Uffizzi::Error) do
      @compose.set
    end

    assert_equal("Environment variable PORT doesn't exist", error.message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_compose_file_with_syntax_error
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    ENV['IMAGE'] = 'nginx'
    ENV['CONFIG_SOURCE'] = 'vote.conf'

    @compose.options = command_options(file: 'test/compose_files/test_compose_with_syntax_error.yml')
    error = assert_raises(Uffizzi::Error) do
      @compose.set
    end

    assert_equal('Syntax error: mapping values are not allowed in this context at line 3 column 10', error.message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_default_env_var_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    ENV['CONFIG_SOURCE'] = 'vote.conf'
    ENV['PORT'] = '80'

    @compose.options = command_options(file: 'test/compose_files/test_compose_with_env_vars.yml')
    @compose.set

    assert_equal('compose file created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_error_env_var_failed
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    ENV['IMAGE'] = 'nginx'
    ENV['PORT'] = '80'

    @compose.options = command_options(file: 'test/compose_files/test_compose_with_env_vars.yml')
    error = assert_raises(Uffizzi::Error) do
      @compose.set
    end

    assert_equal('No_config_source', error.message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_invalid_compose
    body = json_fixture('files/uffizzi/uffizzi_create_compose_without_images.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_failed(body, @project_slug)

    @compose.options = command_options(file: 'test/compose_files/test_compose_without_images.yml')

    error = assert_raises(Uffizzi::ServerResponseError) do
      @compose.set
    end

    expected_error_message = render_server_error(body[:errors][:path].last)

    assert_equal(expected_error_message, error.message.strip)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_invalid_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    @compose.options = command_options(file: 'test/compose_files/test_compose_with_invalid_env_path.yml')

    assert_raises(Uffizzi::Error) do
      @compose.set
    end

    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_empty_path_to_dependency_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_success(body, @project_slug)
    @compose.options = command_options(file: 'test/compose_files/test_compose_with_empty_env_path.yml')

    assert_raises(TypeError) do
      @compose.set
    end

    assert_equal('env_file contains an empty value', Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_set_with_already_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_create_compose_with_already_existed_compose_file.json')
    stubbed_uffizzi_create_compose = stub_uffizzi_create_compose_failed(body, @project_slug)

    @compose.options = command_options(file: 'test/compose_files/test_compose_success.yml')

    error = assert_raises(Uffizzi::ServerResponseError) do
      @compose.set
    end

    expected_error_message = render_server_error(body[:errors][:compose_file].last)

    assert_equal(expected_error_message, error.message.strip)
    assert_requested(stubbed_uffizzi_create_compose)
  end

  def test_compose_unset_success
    body = json_fixture('files/uffizzi/uffizzi_create_compose_success.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_unset_compose_success(body, @project_slug)

    @compose.unset

    assert_equal('compose file deleted', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_unset_with_not_existed_compose_file
    body = json_fixture('files/uffizzi/uffizzi_compose_with_not_existed_compose_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_unset_compose_failed(body, @project_slug)

    error = assert_raises(Uffizzi::ServerResponseError) do
      @compose.unset
    end

    expected_error_message = render_server_error(body[:errors][:compose_file].last)

    assert_equal(expected_error_message, error.message.strip)
    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_describe_valid_file
    body = json_fixture('files/uffizzi/uffizzi_describe_compose_valid_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_describe_compose(body, @project_slug)

    @compose.describe

    assert_requested(stubbed_uffizzi_unset_compose)
  end

  def test_compose_describe_invalid_file
    body = json_fixture('files/uffizzi/uffizzi_describe_compose_invalid_file.json')
    stubbed_uffizzi_unset_compose = stub_uffizzi_describe_compose(body, @project_slug)

    error = assert_raises(Uffizzi::ServerResponseError) do
      @compose.describe
    end

    expected_error_message = render_server_error(body[:compose_file][:payload][:errors][:path].last)

    assert_equal(expected_error_message, error.message.strip)
    assert_requested(stubbed_uffizzi_unset_compose)
  end
end
