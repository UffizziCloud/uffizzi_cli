# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < Minitest::Test
  def setup
    @project = Uffizzi::CLI::Project.new

    sign_in
  end

  def test_project_list_success
    body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects_success(body)

    @project.list

    refute(Uffizzi::ConfigFile.read_option([:project]))

    assert_requested(stubbed_uffizzi_projects)
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

  def test_project_describe_success
    body = json_fixture('files/uffizzi/uffizzi_describe_project.json')
    project_slug = body[:project][:slug]
    stubbed_uffizzi_projects = stub_uffizzi_project_success(body, project_slug)

    @project.describe("#{project_slug}")

    assert_requested(stubbed_uffizzi_projects)
    assert_equal(body[:project], Uffizzi.ui.last_message)
  end
end
