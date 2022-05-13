# frozen_string_literal: true

require 'test_helper'

class SecretTest < Minitest::Test
  def setup
    @secret = Uffizzi::Cli::Project::Secret.new
    @project_slug = 'default'
    Uffizzi::ConfigFile.write_option(:project, @project_slug)

    sign_in
  end

  def test_secret_list_success
    body = json_fixture('files/uffizzi/uffizzi_project_secrets_success.json')
    stubbed_uffizzi_secrets = stub_uffizzi_project_secret_list(body, @project_slug)

    @secret.list

    assert_requested(stubbed_uffizzi_secrets)
  end

  def test_secret_create_success
    body = json_fixture('files/uffizzi/uffizzi_projects_success_one_project.json')
    secret_name = 'my secret'
    secret_value = 'password'
    stubbed_uffizzi_secrets = stub_uffizzi_project_secret_create(body, @project_slug)

    $stdin = StringIO.new(secret_value)
    @secret.create(secret_name)

    assert_equal('The secret was successfully created', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_secrets)
  end

  def test_secret_delete_success
    secret_name = 'my secret'
    stubbed_uffizzi_secrets = stub_uffizzi_project_secret_delete(@project_slug, secret_name)

    @secret.delete(secret_name)

    assert_equal('The secret was successfully deleted', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_secrets)
  end
end
