# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    sign_in
  end

  def test_projects_success
    body = json_fixture('files/uffizzi/uffizzi_projects_success_two_projects.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects(Uffizzi.configuration.hostname, 200, body, {})

    result = @cli.projects

    refute(Uffizzi::ConfigFile.read_option([:project]))

    assert_equal(result, body[:projects])
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_success_with_one_project
    body = json_fixture('files/uffizzi/uffizzi_projects_success_one_project.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects(Uffizzi.configuration.hostname, 200, body, {})

    result = @cli.projects

    assert_equal(result, body[:projects])
    assert_equal(body[:projects].first[:slug], Uffizzi::ConfigFile.read_option(:project))
    assert_requested(stubbed_uffizzi_projects)
  end

  def test_projects_unauthorized
    body = json_fixture('files/uffizzi/uffizzi_projects_failed.json')
    stubbed_uffizzi_projects = stub_uffizzi_projects(Uffizzi.configuration.hostname, 401, body, {})

    error = assert_raises(StandardError) do
      @cli.projects
    end

    assert_match(error.message, 'Not authorized')
    assert_requested(stubbed_uffizzi_projects)
  end
end
