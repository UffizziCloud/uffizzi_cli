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

    refute(Uffizzi::ConfigFile.option_exists?(:server))
    refute(Uffizzi::ConfigFile.option_exists?(:username))

    @cli.options = command_options(username: @command_params[:username], server: @command_params[:server], email: true)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    refute_requested(stubbed_uffizzi_accounts_request)
    assert(Uffizzi::ConfigFile.option_exists?(:server))
    assert(Uffizzi::ConfigFile.option_exists?(:username))
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

    @cli.options = command_options(email: true)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    assert_requested(stubbed_uffizzi_projects)
    assert_equal(Uffizzi.configuration.server, @command_params[:server])
    assert_equal(@command_params[:username], Uffizzi::ConfigFile.read_option(:username))
  end

  def test_login_success_without_username
    body = json_fixture('files/uffizzi/uffizzi_login_success.json')

    stubbed_uffizzi_login = stub_uffizzi_login_success(body)
    # accounts_body = json_fixture('files/uffizzi/uffizzi_accounts_success.json')
    # stubbed_uffizzi_accounts_request = stub_uffizzi_accounts_success(accounts_body)
    account_id = 1
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_account_projects_success(projects_body, account_id)

    refute(Uffizzi::ConfigFile.option_exists?(:server))
    refute(Uffizzi::ConfigFile.option_exists?(:username))
    Uffizzi::ConfigFile.write_option(:project, 'project_slug_1')
    Uffizzi::ConfigFile.write_option(:account, { 'id' => 1, 'name' => 'uffizzi' })

    @cli.options = command_options(server: @command_params[:server], email: true)

    @cli.login

    assert_requested(stubbed_uffizzi_login)
    # assert_requested(stubbed_uffizzi_accounts_request)
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_login_failed
    body = json_fixture('files/uffizzi/uffizzi_login_failed.json')
    stubbed_uffizzi_login = stub_uffizzi_login_failed(body)
    projects_body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_success(projects_body)

    @cli.options = command_options(username: @command_params[:username], server: @command_params[:server], email: true)

    assert_raises(Uffizzi::ServerResponseError) do
      @cli.login
    end

    assert_requested(stubbed_uffizzi_login)
    refute(Uffizzi::ConfigFile.option_exists?(:server))
    refute(Uffizzi::ConfigFile.option_exists?(:username))
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
end
