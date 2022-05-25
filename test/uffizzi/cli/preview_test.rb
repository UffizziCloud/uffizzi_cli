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
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list_success(body, @project_slug)

    deployment = body[:deployments].first

    @preview.list

    assert_equal("deployment-#{deployment[:id]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_list)
  end

  def test_delete_preview_success
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(@project_slug, deployment_id)

    @preview.delete("deployment-#{deployment_id}")

    assert_equal("Preview deployment-#{deployment_id} deleted", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_delete)
  end

  def test_delete_preview_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_failed(body, @project_slug, deployment_id)

    error = assert_raises(Uffizzi::Error) do
      @preview.delete("deployment-#{deployment_id}")
    end

    assert_equal('Resource Not Found', error.message.strip)
    assert_requested(stubbed_uffizzi_preview_delete)
  end

  def test_delete_preview_with_incorrect_input
    deployment_id = 1
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(@project_slug, deployment_id)

    error = assert_raises(Uffizzi::Error) do
      @preview.describe("deployment--#{deployment_id}")
    end

    assert_equal("Preview should be specified in 'deployment-PREVIEW_ID' format", error.message)
    refute_requested(stubbed_uffizzi_preview_delete)
  end

  def test_describe_preview_success
    body = json_fixture('files/uffizzi/uffizzi_preview_describe_success.json')
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe_success(body, @project_slug, deployment_id)

    @preview.describe("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_describe)
  end

  def test_describe_preview_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe_not_found(body, @project_slug, deployment_id)

    error = assert_raises(Uffizzi::Error) do
      @preview.describe("deployment-#{deployment_id}")
    end

    assert_equal('Resource Not Found', error.message.strip)
    assert_requested(stubbed_uffizzi_preview_describe)
  end

  def test_describe_preview_with_incorrect_input
    deployment_id = 1
    stubbed_uffizzi_preview_describe = stub_uffizzi_preview_describe_no_content(nil, @project_slug, deployment_id)

    error = assert_raises(Uffizzi::Error) do
      @preview.describe("deployment--#{deployment_id}")
    end

    assert_equal("Preview should be specified in 'deployment-PREVIEW_ID' format", error.message)
    refute_requested(stubbed_uffizzi_preview_describe)
  end

  def test_create_preview_without_file_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.create

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_without_file_and_unexisted_compose
    create_body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = 1
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_not_found(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    assert_raises(Uffizzi::Error) do
      @preview.create
    end

    refute_requested(stubbed_uffizzi_preview_activity_items)
    refute_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_file_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.create('test/compose_files/test_compose_success.yml')

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_deleting_preview_during_deployment
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_not_found_body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)
    stubbed_uffizzi_deleted_deployment = stub_uffizzi_preview_activity_items_not_found(
      deployment_not_found_body,
      @project_slug,
      deployment_id,
    )

    assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_requested(stubbed_uffizzi_deleted_deployment)
    assert_requested(stubbed_uffizzi_preview_activity_items)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_deploy_interruption
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(@project_slug, deployment_id)

    PreviewService.stubs(:run_containers_deploy).raises(Interrupt)

    assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_requested(stubbed_uffizzi_preview_delete)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_deploy_if_system_exit_error_raises
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(@project_slug, deployment_id)

    PreviewService.stubs(:run_containers_deploy).raises(SystemExit)

    assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_requested(stubbed_uffizzi_preview_delete)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_deploy_if_socket_error_raises
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_delete = stub_uffizzi_preview_delete_success(@project_slug, deployment_id)

    PreviewService.stubs(:run_containers_deploy).raises(SocketError)

    assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_requested(stubbed_uffizzi_preview_delete)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_update_preview_success
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_update_preview_success_with_format
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update(update_body, @project_slug, deployment_id)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items(activity_items_body, @project_slug, deployment_id)

    @preview.options = command_options(output: 'github-action')
    @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')

    assert_match('name=url', Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_update_preview_failed_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_not_found(body, @project_slug, deployment_id)

    error = assert_raises(Uffizzi::Error) do
      @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')
    end

    assert_equal('Resource Not Found', error.message.strip)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_events_preview_success
    events_body = json_fixture('files/uffizzi/uffizzi_preview_events_success.json')
    deployment_id = 1
    stubbed_uffizzi_preview_events_success = stub_uffizzi_preview_events_success(events_body, deployment_id, @project_slug)

    @preview.events("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_events_success)
  end
end
