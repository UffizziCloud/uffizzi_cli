# frozen_string_literal: true

require 'test_helper'

class PreviewTest < Minitest::Test
  def setup
    @preview = Uffizzi::Cli::Preview.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
  end

  def test_list_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_list.json')
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list(200, body, @project_slug)

    deployment = body[:deployments].first

    @preview.list

    assert_equal("deployment-#{deployment[:id]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_list)
  end

  def test_delete_preview_success
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(204, @project_slug, deployment_id)

    @preview.delete("deployment-#{deployment_id}")

    assert_equal("Preview deployment-#{deployment_id} deleted", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_delete)
  end

  def test_delete_preview_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_failed(404, body, @project_slug, deployment_id)

    @preview.delete("deployment-#{deployment_id}")

    assert_equal('Resource Not Found', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_delete)
  end

  def test_delete_preview_with_incorrect_input
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(204, @project_slug, deployment_id)

    @preview.delete("deployment--#{deployment_id}")

    assert_equal("Preview should be specified in 'deployment-PREVIEW_ID' format", Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_preview_delete)
  end

  def test_describe_preview_success
    body = json_fixture('files/uffizzi/uffizzi_preview_describe_success.json')
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe(200, body, @project_slug, deployment_id)

    @preview.describe("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_describe)
  end

  def test_describe_preview_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe(404, body, @project_slug, deployment_id)

    @preview.describe("deployment-#{deployment_id}")

    assert_equal('Resource Not Found', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_describe)
  end

  def test_describe_preview_with_incorrect_input
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe(204, nil, @project_slug, deployment_id)

    @preview.describe("deployment--#{deployment_id}")

    assert_equal("Preview should be specified in 'deployment-PREVIEW_ID' format", Uffizzi.ui.last_message)
    refute_requested(stubbed_uffizzi_preview_describe)
  end

  def test_create_preview_without_file_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create(201, create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers(204, @project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items(200, activity_items_body, @project_slug, deployment_id)

    @preview.create

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_without_file_and_unexisted_compose
    create_body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = 1
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create(404, create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers(204, @project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items(200, activity_items_body, @project_slug, deployment_id)

    @preview.create

    refute_requested(stubbed_uffizzi_preview_activity_items)
    refute_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_file_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create(201, create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers(204, @project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items(200, activity_items_body, @project_slug, deployment_id)

    @preview.create('test/compose_files/test_compose_success.yml')

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_deleteing_preview_during_deployment
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_not_found_body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create(201, create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers(204, @project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items(200, activity_items_body, @project_slug, deployment_id)
    stubbed_uffizzi_deleted_deployment = stub_uffizzi_preview_activity_items(404, deployment_not_found_body, @project_slug, deployment_id)

    @preview.create

    assert_requested(stubbed_uffizzi_deleted_deployment)
    assert_requested(stubbed_uffizzi_preview_activity_items)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_events_preview_success
    events_body = json_fixture('files/uffizzi/uffizzi_preview_events_success.json')
    deployment_id = 1
    stubbed_uffizzi_preview_events_success = stub_uffizzi_preview_events_success(events_body, deployment_id, @project_slug)

    @preview.events("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_events_success)
  end
end
