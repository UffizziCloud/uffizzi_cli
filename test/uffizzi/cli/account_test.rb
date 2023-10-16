# frozen_string_literal: true

require 'test_helper'

class AccountTest < Minitest::Test
  def setup
    @account = Uffizzi::Cli::Account.new
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')

    sign_in
  end

  def test_accounts_list_success
    body = json_fixture('files/uffizzi/uffizzi_accounts_success.json')
    stubbed_uffizzi_accounts = stub_uffizzi_accounts_success(body)

    @account.list

    assert_requested(stubbed_uffizzi_accounts)
  end

  def test_account_set_default_success_with_two_projects
    body = json_fixture('files/uffizzi/uffizzi_account_success_with_two_projects.json')
    account_name = body[:account][:name]
    stubbed_uffizzi_account = stub_uffizzi_account_success(body, account_name)
    refute_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))

    @account.set_default(account_name)

    assert_requested(stubbed_uffizzi_account)
    assert_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))
    assert_nil(Uffizzi::ConfigFile.read_option(:project))
  end

  def test_account_set_default_success_without_projects
    body = json_fixture('files/uffizzi/uffizzi_account_success_without_projects.json')
    account_name = body[:account][:name]
    stubbed_uffizzi_account = stub_uffizzi_account_success(body, account_name)
    account_id = body[:account][:id]
    project_body = json_fixture('files/uffizzi/uffizzi_project_success.json')
    stubbed_uffizzi_project = stub_uffizzi_project_create_success(project_body, account_id)
    refute_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))

    @account.set_default(account_name)

    assert_requested(stubbed_uffizzi_account)
    assert_requested(stubbed_uffizzi_project)
    assert_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))
    assert_equal(project_body[:project][:slug], Uffizzi::ConfigFile.read_option(:project))
  end

  def test_account_set_default_success_with_one_project
    body = json_fixture('files/uffizzi/uffizzi_account_success_with_one_project.json')
    account_name = body[:account][:name]
    stubbed_uffizzi_account = stub_uffizzi_account_success(body, account_name)
    project_slug = body[:account][:projects].first[:slug]
    refute_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))
    refute_equal(project_slug, Uffizzi::ConfigFile.read_option(:project))

    @account.set_default(account_name)

    assert_requested(stubbed_uffizzi_account)
    assert_equal(account_name, Uffizzi::ConfigFile.read_option(:account, :name))
    assert_equal(project_slug, Uffizzi::ConfigFile.read_option(:project))
  end
end
