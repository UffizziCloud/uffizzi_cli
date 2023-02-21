# frozen_string_literal: true

require 'test_helper'
require 'byebug'

class PreviewTest < Minitest::Test
  def setup
    @preview = Uffizzi::Cli::Preview.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    ENV.delete('IMAGE')
    ENV.delete('CONFIG_SOURCE')
    ENV.delete('PORT')
    ENV['GITHUB_OUTPUT'] = '/tmp'
    Uffizzi.ui.output_format = nil
  end

  def test_list_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_list.json')
    filter = {}
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list_success(body, @project_slug, filter)

    deployment = body[:deployments].first

    @preview.list

    assert_equal("deployment-#{deployment[:id]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_list)
  end

  def test_list_preview_with_output_option
    body = json_fixture('files/uffizzi/uffizzi_preview_list.json')
    filter = {}
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list_success(body, @project_slug, filter)

    deployments = body[:deployments]

    @preview.options = command_options(output: Uffizzi::UI::Shell::PRETTY_JSON)
    @preview.list

    assert_equal(JSON.pretty_generate(deployments), Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_list)
  end

  def test_list_preview_with_filter_success
    body = json_fixture('files/uffizzi/uffizzi_preview_list.json')
    filter = {
      'labels' => {
        'github' => {
          'repository' => 'UffizziCloud/example-voting-app',
          'pull_request' => {
            'number' => '23',
          },
        },
      },
    }
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list_success(body, @project_slug, filter)

    deployment = body[:deployments].first

    @preview.options = command_options(filter: 'github.repository=UffizziCloud/example-voting-app github.pull_request.number=23')
    @preview.list

    assert_equal("deployment-#{deployment[:id]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_list)
  end

  def test_list_preview_with_filter_without_key
    body = json_fixture('files/uffizzi/uffizzi_preview_list.json')
    filter = {
      'labels' => {
        'github' => {
          'repository' => 'UffizziCloud/example-voting-app',
          'pull_request' => {
            'number' => '23',
          },
        },
      },
    }
    stubbed_uffizzi_preview_list = stub_uffizzi_preview_list_success(body, @project_slug, filter)

    @preview.options = command_options(filter: 'github.repository=UffizziCloud/example-voting-app =23')
    error = assert_raises(Uffizzi::Error) do
      @preview.list
    end

    assert_equal(error.message, 'Filtering parameters were set in incorrect format.')
    refute_requested(stubbed_uffizzi_preview_list)
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

    error = assert_raises(Uffizzi::ServerResponseError) do
      @preview.delete("deployment-#{deployment_id}")
    end

    expected_error_message = render_server_error("Resource Not Found\n")

    assert_equal(expected_error_message, error.message)
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

    error = assert_raises(Uffizzi::ServerResponseError) do
      @preview.describe("deployment-#{deployment_id}")
    end

    expected_error_message = render_server_error("Resource Not Found\n")

    assert_equal(expected_error_message, error.message)
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

  def test_create_preview_with_labels_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_with_labels_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app github.pull_request.number=23')
    @preview.create

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_label_without_key
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_with_labels_success.json')
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app =23')
    error = assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_equal(error.message, 'Labels were set in incorrect format.')
    refute_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_label_with_incorrect_key
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_with_labels_success.json')
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app github.pull_request..number=23')
    error = assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_equal(error.message, 'Labels were set in incorrect format.')
    refute_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_label_without_value
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_with_labels_success.json')
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app github.pull_request.number=')
    error = assert_raises(Uffizzi::Error) do
      @preview.create
    end

    assert_equal(error.message, 'Labels were set in incorrect format.')
    refute_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_without_file_and_unexisted_compose
    create_body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = 1
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_not_found(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    assert_raises(Uffizzi::ServerResponseError) do
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

    @preview.options = command_options("creation-source": 'github_actions')

    # rubocop:disable Layout/LineLength
    expected_data = {
      creation_source: 'github_actions',
      compose_file: {
        content: Base64.encode64(File.read('test/compose_files/test_compose_success.yml')),
        path: File.expand_path('test/compose_files/test_compose_success.yml'),
        source: File.expand_path('test/compose_files/test_compose_success.yml'),
      },
      dependencies: [
        {
          content: "S0VZPXZhbHVl\n",
          path: 'env_files/env_file.env',
          source: 'env_files/env_file.env',
          use_kind: 'config_map',
        },
        {
          content: "UE9TVEdSRVNfVVNFUj1wb3N0Z3JlcyBQT1NUR1JFU19QQVNTV09SRD1wb3N0\nZ3Jlcw==\n",
          path: 'local.env',
          source: 'local.env',
          use_kind: 'config_map',
        },
        {
          content: "c2VydmVyIHsgbGlzdGVuICAgICAgIDg4ODg7IHNlcnZlcl9uYW1lICBsb2Nh\nbGhvc3Q7IGxvY2F0aW9uIC8geyBwcm94eV9wYXNzICAgICAgaHR0cDovLzEy\nNy4wLjAuMTo4MDg4LzsgfSBsb2NhdGlvbiAvdm90ZS8geyBwcm94eV9wYXNz\nICAgICAgaHR0cDovLzEyNy4wLjAuMTo4ODg4LzsgfSB9\n",
          path: 'config_files/config_file.conf',
          source: 'config_files/config_file.conf',
          use_kind: 'config_map',
        },
        {
          content: "c2VydmVyIHsgbGlzdGVuICAgICAgIDgwODA7IHNlcnZlcl9uYW1lICBsb2Nh\nbGhvc3Q7IGxvY2F0aW9uIC8geyBwcm94eV9wYXNzICAgICAgaHR0cDovLzEy\nNy4wLjAuMTo4MDg4LzsgfSBsb2NhdGlvbiAvdm90ZS8geyBwcm94eV9wYXNz\nICAgICAgaHR0cDovLzEyNy4wLjAuMTo4ODg4LzsgfSB9\n",
          path: 'vote.conf',
          source: 'vote.conf',
          use_kind: 'config_map',
        },
        {
          content: "ZGF0YQ==\n",
          is_file: false,
          path: File.expand_path('test/compose_files/volume_files'),
          source: './volume_files',
          use_kind: 'volume',
        },
        {
          content: "ZGF0YQ==\n",
          is_file: true,
          path: File.expand_path('test/compose_files/volume_files/some_text_2.txt'),
          source: './volume_files/some_text_2.txt',
          use_kind: 'volume',
        },
        {
          content: "ZGF0YQ==\n",
          is_file: true,
          path: File.expand_path('test/compose_files/volume_files/some_text_1.txt'),
          source: './volume_files/some_text_1.txt',
          use_kind: 'volume',
        },
      ],
    }
    # rubocop:enable Layout/LineLength

    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success_with_expected(create_body, @project_slug, expected_data)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    File.stub(:binread, 'data') do
      @preview.create('test/compose_files/test_compose_success.yml')
    end

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

    assert_raises(Uffizzi::ServerResponseError) do
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

  def test_preview_create_with_default_env_var_success
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)
    ENV['CONFIG_SOURCE'] = 'vote.conf'
    ENV['PORT'] = '80'

    @preview.create('test/compose_files/test_compose_with_env_vars.yml')

    assert_equal("Deployment url: https://#{create_body[:deployment][:preview_url]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_preview_create_with_env_vars_failed
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    ENV['IMAGE'] = 'nginx'
    ENV['CONFIG_SOURCE'] = 'vote.conf'

    error = assert_raises(Uffizzi::Error) do
      @preview.create('test/compose_files/test_compose_with_env_vars.yml')
    end

    assert_equal("Environment variable PORT doesn't exist", error.message)
    refute_requested(stubbed_uffizzi_preview_create)
  end

  def test_preview_create_with_error_env_var_failed
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)

    ENV['IMAGE'] = 'nginx'
    ENV['PORT'] = '80'

    error = assert_raises(Uffizzi::Error) do
      @preview.create('test/compose_files/test_compose_with_env_vars.yml')
    end

    assert_equal('No_config_source', error.message)
    refute_requested(stubbed_uffizzi_preview_create)
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
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.options = command_options(output: Uffizzi::UI::Shell::REGULAR_JSON)
    @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')

    last_message = Uffizzi.ui.last_message
    data = JSON.parse(last_message)
    assert_equal("deployment-#{deployment_id}", data['id'])
    assert_equal('https://preview_url', data['url'])
    assert_equal('http://web:7000/projects/2/deployments/160/containers', data['containers_uri'])

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_update_preview_failed_with_unexisted_preview
    body = json_fixture('files/uffizzi/uffizzi_preview_resource_not_found.json')
    deployment_id = 1
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_not_found(body, @project_slug, deployment_id)

    error = assert_raises(Uffizzi::ServerResponseError) do
      @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')
    end

    expected_error_message = render_server_error("Resource Not Found\n")

    assert_equal(expected_error_message, error.message)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_preview_update_with_default_env_var_success
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)
    ENV['CONFIG_SOURCE'] = 'vote.conf'
    ENV['PORT'] = '80'

    @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_with_env_vars.yml')

    assert_equal("Deployment url: https://#{update_body[:deployment][:preview_url]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_preview_update_with_env_vars_failed
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)
    ENV['IMAGE'] = 'nginx'
    ENV['CONFIG_SOURCE'] = 'vote.conf'

    error = assert_raises(Uffizzi::Error) do
      @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_with_env_vars.yml')
    end

    assert_equal("Environment variable PORT doesn't exist", error.message)
    refute_requested(stubbed_uffizzi_preview_update)
  end

  def test_preview_update_with_error_env_var_failed
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)

    ENV['IMAGE'] = 'nginx'
    ENV['PORT'] = '80'

    error = assert_raises(Uffizzi::Error) do
      @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_with_env_vars.yml')
    end

    assert_equal('No_config_source', error.message)
    refute_requested(stubbed_uffizzi_preview_update)
  end

  def test_update_preview_with_labels_success
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app github.pull_request.number=23')
    @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_update)
  end

  def test_update_preview_with_label_without_key
    update_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    deployment_id = update_body[:deployment][:id]
    stubbed_uffizzi_preview_update = stub_uffizzi_preview_update_success(update_body, @project_slug, deployment_id)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app =23')
    error = assert_raises(Uffizzi::Error) do
      @preview.update("deployment-#{deployment_id}", 'test/compose_files/test_compose_success.yml')
    end

    assert_equal(error.message, 'Labels were set in incorrect format.')
    refute_requested(stubbed_uffizzi_preview_update)
  end

  def test_events_preview_success
    events_body = json_fixture('files/uffizzi/uffizzi_preview_events_success.json')
    deployment_id = 1
    stubbed_uffizzi_preview_events_success = stub_uffizzi_preview_events_success(events_body, deployment_id, @project_slug)

    @preview.events("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_events_success)
  end

  def test_create_preview_with_yaml_alias
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)
    ENV['CONFIG_SOURCE'] = 'vote.conf'
    ENV['PORT'] = '80'

    @preview.create('test/compose_files/test_compose_with_alias.yml')

    assert_equal("Deployment url: https://#{create_body[:deployment][:preview_url]}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_substitution_env
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    ENV['IMAGE'] = 'nginx'
    expected_content = YAML.safe_load(File.read('test/compose_files/test_compose_with_substitution_env.yml'))
    expected_content['services']['hello-world']['image'] = ENV['IMAGE']

    comparator = Proc.new do |expected_data, actual_request_body|
      actual_content = Base64.decode64(actual_request_body[:compose_file][:content])
      expected_data == YAML.safe_load(actual_content).to_yaml
    end

    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success_with_expected(create_body, @project_slug, expected_content.to_yaml,
                                                                                       comparator)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_success(activity_items_body, @project_slug, deployment_id)

    @preview.create('test/compose_files/test_compose_with_substitution_env.yml')

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 2)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)
  end

  def test_create_preview_with_failed_deployment
    create_body = json_fixture('files/uffizzi/uffizzi_preview_create_with_labels_success.json')
    activity_items_body = json_fixture('files/uffizzi/uffizzi_preview_activity_items_deployed.json')
    deployment_id = create_body[:deployment][:id]
    web_service_name = create_body[:deployment][:containers][0][:service_name]
    redis_service_name = create_body[:deployment][:containers][1][:service_name]
    stubbed_uffizzi_preview_create = stub_uffizzi_preview_create_success(create_body, @project_slug)
    stubbed_uffizzi_preview_deploy_containers = stub_uffizzi_preview_deploy_containers_success(@project_slug, deployment_id)
    failed_response_body_for_activity_items = { 'errors' => { 'title' => ["Preview with ID deployment-#{deployment_id} failed"] } }
    stubbed_uffizzi_preview_activity_items = stub_uffizzi_preview_activity_items_unprocessable_entity(
      failed_response_body_for_activity_items, @project_slug, deployment_id
    )

    k8s_container_last_state = {
      code: 127,
      reason: 'MOOKiller',
      exit_code: 999,
      started_at: Time.now,
      finished_at: Time.now,
    }
    stub_uffizzi_k8s_container_description_success({ last_state: k8s_container_last_state }, @project_slug, deployment_id, web_service_name)
    stub_uffizzi_k8s_container_description_success({}, @project_slug, deployment_id, redis_service_name)

    @preview.options = command_options("set-labels": 'github.repository=UffizziCloud/example-voting-app github.pull_request.number=23')

    error = assert_raises(Uffizzi::ServerResponseError) do
      PreviewService.stub(:wait_containers_creation, activity_items_body[:activity_items]) do
        @preview.create
      end
    end

    assert_requested(stubbed_uffizzi_preview_activity_items, times: 1)
    assert_requested(stubbed_uffizzi_preview_deploy_containers)
    assert_requested(stubbed_uffizzi_preview_create)

    expected_msg = "Preview with ID deployment-#{deployment_id} failed\n"\
                   "Last State for container '#{web_service_name}':\n"\
                   " code: #{k8s_container_last_state[:code]}\n"\
                   " reason: #{k8s_container_last_state[:reason]}\n"\
                   " exit_code: #{k8s_container_last_state[:exit_code]}\n"\
                   " started_at: #{k8s_container_last_state[:started_at]}\n"\
                   " finished_at: #{k8s_container_last_state[:finished_at]}\n"
    assert_equal(render_server_error(expected_msg), error.message)
  end
end
