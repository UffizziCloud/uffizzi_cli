# frozen_string_literal: true

require 'test_helper'

class LoginTest < Minitest::Test
  def setup
    @cli = Uffizzi::Cli.new

    @command_params = {
      username: generate(:email),
      password: generate(:string),
      server: Uffizzi.configuration.server,
    }
  end

  def test_login_success_from_ci_pipeline
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    stubbed_uffizzi_login = stub_uffizzi_login_success(body)
    accounts_body = json_fixture('files/uffizzi/uffizzi_accounts_success.json')
    stubbed_uffizzi_accounts_request = stub_uffizzi_accounts_success(accounts_body)
    ENV.stubs(:fetch).returns(true)

    refute(File.exist?(Uffizzi::ConfigFile.config_path))

    @cli.options = command_options(username: @command_params[:username], server: @command_params[:server], email: true)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    refute_requested(stubbed_uffizzi_accounts_request)
    assert(Uffizzi::ConfigFile.option_exists?(:server))
    assert(Uffizzi::ConfigFile.option_exists?(:username))
    assert(Uffizzi::ConfigFile.option_exists?(:account))
  end

  def test_login_success_with_options_from_config
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    stubbed_uffizzi_login = stub_uffizzi_login_success(body)
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    account_id = 1
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)

    Uffizzi::ConfigFile.write_option(:server, Uffizzi.configuration.server)
    Uffizzi::ConfigFile.write_option(:username, @command_params[:username])
    Uffizzi::ConfigFile.write_option(:project, 'project_slug_1')
    Uffizzi::ConfigFile.write_option(:account, { 'id' => 1, 'name' => 'uffizzi' })

    @cli.options = command_options(email: '')
    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert_requested(stubbed_uffizzi_projects)
    assert_equal(Uffizzi.configuration.server, @command_params[:server])
    assert_equal(@command_params[:username], Uffizzi::ConfigFile.read_option(:username))
  end

  def test_login_success_without_username
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login_success(body)
    account_id = 1
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)

    refute(File.exist?(Uffizzi::ConfigFile.config_path))
    Uffizzi::ConfigFile.write_option(:project, 'project_slug_1')
    Uffizzi::ConfigFile.write_option(:account, { 'id' => 1, 'name' => 'uffizzi' })

    @cli.options = command_options(server: @command_params[:server], email: true)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_login_failed
    body = json_fixture('files/uffizzi/uffizzi_login_failed.json')
    stubbed_uffizzi_login = stub_uffizzi_login_failed(body)
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_success(projects_body)

    @cli.options = command_options(username: @command_params[:username], server: @command_params[:server], email: 'wrong@email.com')

    assert_raises(Uffizzi::ServerResponseError) do
      @cli.login
    end

    assert_requested(stubbed_uffizzi_login)
    refute(File.exist?(Uffizzi::ConfigFile.config_path))
    refute_requested(stubbed_uffizzi_projects)
  end

  def test_browser_login
    access_token_body = json_fixture('files/uffizzi/uffizzi_access_token_success.json')
    stubbed_create_access_token = stub_create_token_request(access_token_body)
    stubbed_get_access_token = stub_get_token_request(access_token_body)
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    account_id = 1
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)
    Uffizzi::ConfigFile.write_option(:project, 'project_slug_1')
    Uffizzi::ConfigFile.write_option(:account, { 'id' => 1, 'name' => 'uffizzi' })

    @cli.options = command_options(server: @command_params[:server])
    @cli.login

    assert_requested(stubbed_create_access_token)
    assert_requested(stubbed_get_access_token)
    assert_requested(stubbed_uffizzi_projects)
    assert(Uffizzi::Token.exists?)
  end

  def test_browser_login_with_new_project_creation_success
    account_id = 1
    access_token_body = json_fixture('files/uffizzi/uffizzi_access_token_success.json')
    account_body = json_fixture('files/uffizzi/uffizzi_accounts_success.json')
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    project_body = json_fixture('files/uffizzi/uffizzi_project_success.json')

    stubbed_create_access_token = stub_create_token_request(access_token_body)
    stubbed_get_access_token = stub_get_token_request(access_token_body)
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)
    stubbed_uffizzi_project = stub_uffizzi_project_create_success(project_body, account_id)
    stubbed_uffizzi_accounts = stub_uffizzi_accounts_success(account_body)

    @mock_prompt.promise_question_answer('Select an account:', :first)
    @mock_prompt.promise_question_answer('Select a project or create a new project:', :last)
    @mock_prompt.promise_question_answer('Project name: ', 'new-project')
    @mock_prompt.promise_question_answer('Project slug: ', nil)
    @mock_prompt.promise_question_answer('Project desciption: ', 'some desc')
    Uffizzi::ConfigFile.write_option(:project, nil)
    Uffizzi::ConfigFile.write_option(:account, nil)

    @cli.options = command_options(server: @command_params[:server])
    @cli.login

    assert_requested(stubbed_create_access_token)
    assert_requested(stubbed_get_access_token)
    assert_requested(stubbed_uffizzi_projects)
    assert_requested(stubbed_uffizzi_project)
    assert_requested(stubbed_uffizzi_accounts)
  end

  def test_browser_login_with_new_project_creation_when_project_already_exists_and_abort_repeat
    account_id = 1
    access_token_body = json_fixture('files/uffizzi/uffizzi_access_token_success.json')
    account_body = json_fixture('files/uffizzi/uffizzi_accounts_success.json')
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')

    project_creation_error = {
      errors: {
        name: ["A project with the name 'existing-project' already exists."],
      },
    }

    stubbed_create_access_token = stub_create_token_request(access_token_body)
    stubbed_get_access_token = stub_get_token_request(access_token_body)
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)
    stubbed_uffizzi_create_project = stub_uffizzi_project_create_failed(project_creation_error, account_id)
    stubbed_uffizzi_accounts = stub_uffizzi_accounts_success(account_body)

    @mock_prompt.promise_question_answer('Select an account:', :first)
    @mock_prompt.promise_question_answer('Select a project or create a new project:', :last)
    @mock_prompt.promise_question_answer('Project name: ', 'existing-project')
    @mock_prompt.promise_question_answer('Project slug: ', nil)
    @mock_prompt.promise_question_answer('Project desciption: ', 'some desc')
    @mock_prompt.promise_question_answer('Do you want to try different project params?', 'y')
    @mock_prompt.promise_question_answer('Project name: ', 'new-project')
    @mock_prompt.promise_question_answer('Project slug: ', nil)
    @mock_prompt.promise_question_answer('Project desciption: ', 'some desc')
    @mock_prompt.promise_question_answer('Do you want to try different project params?', 'n')
    Uffizzi::ConfigFile.write_option(:project, nil)
    Uffizzi::ConfigFile.write_option(:account, nil)

    @cli.options = command_options(server: @command_params[:server])

    error = assert_raises(Uffizzi::Error) do
      @cli.login
    end

    assert_requested(stubbed_create_access_token)
    assert_requested(stubbed_get_access_token)
    assert_requested(stubbed_uffizzi_projects)
    assert_requested(stubbed_uffizzi_create_project, times: 2)
    assert_requested(stubbed_uffizzi_accounts)
    assert_match('Project creation aborted', error.message)
  end
end
