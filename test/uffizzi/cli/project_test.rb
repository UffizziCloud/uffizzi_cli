# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < Minitest::Test
  def setup
    @project = Uffizzi::Cli::Project.new

    sign_in
  end

  def test_project_list_success
    body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_success(body)

    @project.list

    refute(Uffizzi::ConfigFile.read_option([:project]))

    assert_requested(stubbed_uffizzi_projects)
  end

  def test_project_create_success
    body = json_fixture('files/uffizzi/uffizzi_project_success.json')
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    account_id = login_body[:user][:accounts].first[:id].to_s
    stubbed_uffizzi_project = stub_uffizzi_project_create_success(body, account_id)
    @project.options = {
      name: 'name',
      description: 'project description',
      slug: 'project_slug_1',
    }

    @project.create

    assert_requested(stubbed_uffizzi_project)
  end

  def test_project_create_invalid_slug_failure
    @project.options = {
      name: 'name',
      description: 'project description',
      slug: 'project_slug*',
    }

    error = assert_raises(Uffizzi::Error) do
      @project.create
    end

    assert_equal('Slug must not content spaces or special characters', error.message)
  end

  def test_project_delete_success
    project_slug = 'project_slug_1'
    body = json_fixture('files/uffizzi/uffizzi_project_success.json')
    stubbed_uffizzi_project = stub_uffizzi_project_delete_success(body, project_slug)

    @project.delete(project_slug)

    assert_requested(stubbed_uffizzi_project)
  end

  def test_project_list_success_with_one_project
    body = json_fixture('files/uffizzi/uffizzi_projects_success_one_project.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_success(body)

    @project.list

    assert_equal(body[:projects].first[:slug], Uffizzi::ConfigFile.read_option(:project))
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_project_list_unauthorized
    body = json_fixture('files/uffizzi/uffizzi_projects_failed.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_failed(body)

    error = assert_raises(StandardError) do
      @project.list
    end

    assert_match(error.message, 'Not authorized')
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_project_set_default_success
    body = json_fixture('files/uffizzi/uffizzi_projects_set_default_success.json')
    project_slug = body[:project][:slug]
    stubbed_uffizzi_projects = stub_uffizzi_project_success(body, project_slug)

    refute_equal(project_slug, Uffizzi::ConfigFile.read_option(:project))

    @project.set_default(project_slug)

    assert_equal(project_slug, Uffizzi::ConfigFile.read_option(:project))
    assert_equal('Default project has been updated.', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_project_set_default_failed
    body = json_fixture('files/uffizzi/uffizzi_projects_set_default_with_unexisted_project.json')
    project_slug = 'test'
    stubbed_uffizzi_projects = stub_uffizzi_project_failed(body, project_slug)

    error = assert_raises(Uffizzi::Error) do
      @project.set_default(project_slug)
    end

    assert_match(error.message, "Resource Not Found\n")
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_project_describe_success
    body = json_fixture('files/uffizzi/uffizzi_describe_project.json')
    project_slug = body[:project][:slug]
    stubbed_uffizzi_projects = stub_uffizzi_project_success(body, project_slug)

    @project.options = { output: 'json' }

    @project.describe(project_slug.to_s)

    assert_requested(stubbed_uffizzi_projects)
    assert_equal(body[:project].to_json, Uffizzi.ui.last_message)
  end
end
