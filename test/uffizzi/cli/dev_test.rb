# frozen_string_literal: true

require 'psych'
require 'base64'
require 'test_helper'

class DevTest < Minitest::Test
  def setup
    @dev = Uffizzi::Cli::Dev.new
    @mock_prompt = MockPrompt.new
    Uffizzi.stubs(:prompt).returns(@mock_prompt)

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    tmp_dir_name = (Time.now.utc.to_f * 100_000).to_i
    @kubeconfig_path = "/tmp/test/#{tmp_dir_name}/test-kubeconfig.yaml"
    @skaffold_file_path = "/tmp/test/#{tmp_dir_name}/skaffold.yaml"
    FileUtils.mkdir_p(File.dirname(@skaffold_file_path))
    File.write(@skaffold_file_path, '')
  end

  def test_start_dev
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: 'Good')

    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)

    assert_match('deleted', Uffizzi.ui.last_message)
    assert_nil(cluster_from_config)
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_start_dev_with_existed_current_context
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    existing_kubeconfig = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig))).deep_dup
    existing_kubeconfig['users'][0]['name'] = 'another-user-name'
    existing_kubeconfig['clusters'][0]['name'] = 'another-cluster-name'
    existing_kubeconfig['contexts'][0]['name'] = 'another-context-name'
    existing_kubeconfig['contexts'][0]['context']['cluster'] = existing_kubeconfig['clusters'][0]['name']
    existing_kubeconfig['contexts'][0]['context']['user'] = existing_kubeconfig['users'][0]['name']
    existing_kubeconfig['current-context'] = existing_kubeconfig['clusters'][0]['name']

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, existing_kubeconfig.to_yaml)

    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: 'Good')

    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)
    current_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))

    assert_match('deleted', Uffizzi.ui.last_message)
    assert_nil(cluster_from_config)
    assert_equal(existing_kubeconfig['current-context'], current_kubeconfig['current-context'])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_start_dev_as_daemon
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: 'Good')
    @dev.options = command_options(quiet: true)

    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)

    assert_match('deleted', Uffizzi.ui.last_message)
    assert_nil(cluster_from_config)
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_start_dev_as_daemon_when_deamon_already_run
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: 'Good')
    @dev.options = command_options(quiet: true)
    File.write(DevService.pid_path, '1000')
    @mock_process.pid = 1000

    error = assert_raises(MockShell::ExitError) do
      @dev.start(@skaffold_file_path)
    end

    assert_match('You have already started uffizzi', error.message)
  end

  def test_start_dev_without_skaffold_config
    File.delete(@skaffold_file_path)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')

    error = assert_raises(MockShell::ExitError) do
      @dev.start(@skaffold_file_path)
    end

    assert_match('Please provide a valid config', error.message)
  end

  def test_start_dev_with_kubeconfig_and_default_repo_flags
    default_repo = 'ttl.sh'
    kubeconfig_path = '/tmp/some_path'
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    skaffold_dev_regex = /skaffold dev --filename='.*' --default-repo='#{default_repo}' --kubeconfig='#{kubeconfig_path}'/
    @mock_shell.promise_execute(skaffold_dev_regex, stdout: 'Good')

    @dev.options = command_options('default-repo': default_repo, kubeconfig: kubeconfig_path)
    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)

    assert_match('deleted', Uffizzi.ui.last_message)
    assert_nil(cluster_from_config)
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_describe_dev_by_name
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    config_path1 = '/skaffold.yaml'
    config_path2 = '/skaffold_2.yaml'
    cluster_name1 = cluster_get_body.dig(:cluster, :name)
    cluster_name2 = 'cluster-2'
    dev_environments = [
      { name: cluster_name1, config_path: config_path1 },
      { name: cluster_name2, config_path: config_path2 },
    ]

    Uffizzi::ConfigFile.write_option(:dev_environments, dev_environments)

    @dev.describe(cluster_name1)

    assert_match("- CONFIG_PATH: #{config_path1}", Uffizzi.ui.last_message)
    assert_match("- NAME: #{cluster_name1}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_describe_single_dev
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    config_path = '/skaffold.yaml'
    cluster_name = cluster_get_body.dig(:cluster, :name)
    dev_environments = [{ name: cluster_name, config_path: config_path }]
    Uffizzi::ConfigFile.write_option(:dev_environments, dev_environments)

    @dev.describe

    assert_match("- CONFIG_PATH: #{config_path}", Uffizzi.ui.last_message)
    assert_match("- NAME: #{cluster_name}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_describe_multiple_dev
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    config_path1 = '/skaffold.yaml'
    config_path2 = '/skaffold_2.yaml'
    cluster_name1 = cluster_get_body.dig(:cluster, :name)
    cluster_name2 = 'cluster-2'
    dev_environments = [
      { name: cluster_name1, config_path: config_path1 },
      { name: cluster_name2, config_path: config_path2 },
    ]

    @mock_prompt.promise_question_answer(/You have several dev environments/, :first)

    Uffizzi::ConfigFile.write_option(:dev_environments, dev_environments)

    @dev.describe

    assert_match("- CONFIG_PATH: #{config_path1}", Uffizzi.ui.last_message)
    assert_match("- NAME: #{cluster_name1}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_describe_zero_dev
    @dev.describe

    assert_match('No running dev environments', Uffizzi.ui.last_message)
  end

  def test_describe_dev_with_wrong_name
    name = 'wrong_name'

    @dev.describe(name)

    assert_match('No running dev environment', Uffizzi.ui.last_message)
  end
end
