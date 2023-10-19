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
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/ps -ef/, stdout: File.open(full_path_fixture('files/uffizzi/process_list.txt')))
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: [], waiter: { pid: 4068842 })

    @dev.options = command_options(kubeconfig: @kubeconfig_path)
    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)
    dev_environment_from_config = Uffizzi::ConfigFile.read_option(:dev_environment)

    assert_equal(@kubeconfig_path, cluster_from_config.first[:kubeconfig_path])
    assert_equal(DevService::CLUSTER_DEPLOYED_STATE, dev_environment_from_config[:state])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_start_dev_with_existed_current_context
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

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
    @mock_shell.promise_execute(/ps -ef/, stdout: File.open(full_path_fixture('files/uffizzi/process_list.txt')))
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: [], waiter: { pid: 4068842 })

    @dev.options = command_options(kubeconfig: @kubeconfig_path)
    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)
    dev_environment_from_config = Uffizzi::ConfigFile.read_option(:dev_environment)
    current_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))

    assert_equal(@kubeconfig_path, cluster_from_config.first[:kubeconfig_path])
    assert_equal(DevService::CLUSTER_DEPLOYED_STATE, dev_environment_from_config[:state])
    refute_equal(existing_kubeconfig['current-context'], current_kubeconfig['current-context'])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_start_dev_as_daemon
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(/ps -ef/, stdout: File.open(full_path_fixture('files/uffizzi/process_list.txt')))
    @mock_shell.promise_execute(/skaffold dev --filename/, stdout: [], waiter: { pid: 4068842 })
    @dev.options = command_options(quiet: true)

    @dev.options = command_options(kubeconfig: @kubeconfig_path)
    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)
    dev_environment_from_config = Uffizzi::ConfigFile.read_option(:dev_environment)

    assert_equal(@kubeconfig_path, cluster_from_config.first[:kubeconfig_path])
    assert_equal(DevService::CLUSTER_DEPLOYED_STATE, dev_environment_from_config[:state])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_start_dev_as_daemon_when_deamon_already_run
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @dev.options = command_options(quiet: true)
    dev_environment = { state: DevService::CLUSTER_DEPLOYED_STATE }
    Uffizzi::ConfigFile.write_option(:dev_environment, dev_environment)
    File.write(DevService.pid_path, '1000')
    @mock_process.pid = 1000

    error = assert_raises(MockShell::ExitError) do
      @dev.options = command_options(kubeconfig: @kubeconfig_path)
      @dev.start(@skaffold_file_path)
    end

    assert_match('You have already started uffizzi', error.message)
  end

  def test_start_dev_without_skaffold_config
    File.delete(@skaffold_file_path)
    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')

    error = assert_raises(MockShell::ExitError) do
      @dev.options = command_options(kubeconfig: @kubeconfig_path)
      @dev.start(@skaffold_file_path)
    end

    assert_match('A valid dev environment configuration is required', error.message)
  end

  def test_start_dev_with_kubeconfig_and_default_repo_flags
    default_repo = 'ttl.sh'
    kubeconfig_path = '/tmp/some_path'
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    skaffold_dev_regex = /skaffold dev --filename='.*' --default-repo='#{default_repo}' --kubeconfig='#{kubeconfig_path}'/

    @mock_shell.promise_execute(/skaffold version/, stdout: 'v.2.7.1')
    @mock_shell.promise_execute(skaffold_dev_regex, stdout: [], waiter: { pid: 4068842 })
    @mock_shell.promise_execute(/ps -ef/, stdout: File.open(full_path_fixture('files/uffizzi/process_list.txt')))

    @dev.options = command_options('default-repo': default_repo, kubeconfig: kubeconfig_path)
    @dev.start(@skaffold_file_path)

    cluster_from_config = Uffizzi::ConfigFile.read_option(:clusters)

    assert_equal(kubeconfig_path, cluster_from_config.first[:kubeconfig_path])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_describe_single_dev
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    config_path = '/skaffold.yaml'
    cluster_name = cluster_get_body.dig(:cluster, :name)
    dev_environment = { cluster_name: cluster_name, config_path: config_path }
    Uffizzi::ConfigFile.write_option(:dev_environment, dev_environment)
    File.write(DevService.pid_path, @mock_process.pid)

    @dev.describe

    assert_match("- CONFIG_PATH: #{config_path}", Uffizzi.ui.last_message)
    assert_match("- NAME: #{cluster_name}", Uffizzi.ui.last_message)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_describe_zero_dev
    error = assert_raises(MockShell::ExitError) do
      @dev.describe
    end

    assert_match('Uffizzi dev is not running', error.message)
  end

  def test_stop_when_dev_exist
    config_path = '/skaffold.yaml'
    cluster_name = 'my-cluster'
    dev_environment = { cluster_name: cluster_name, config_path: config_path }
    Uffizzi::ConfigFile.write_option(:dev_environment, dev_environment)
    File.write(DevService.pid_path, @mock_process.pid)

    @dev.stop

    dev_environment_from_config = Uffizzi::ConfigFile.read_option(:dev_environment)

    assert_match('Uffizzi dev was stopped', Uffizzi.ui.last_message)
    assert_match(cluster_name, dev_environment_from_config[:cluster_name])
  end

  def test_stop_when_dev_not_exist
    error = assert_raises(MockShell::ExitError) do
      @dev.stop
    end

    assert_match('Uffizzi dev is not running', error.message)
  end

  def test_delete_when_dev_exist
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    config_path = '/skaffold.yaml'
    cluster_name = cluster_get_body.dig(:cluster, :name)
    dev_environment = { cluster_name: cluster_name, config_path: config_path }
    Uffizzi::ConfigFile.write_option(:dev_environment, dev_environment)
    File.write(DevService.pid_path, @mock_process.pid)

    @dev.delete

    dev_environment_from_config = Uffizzi::ConfigFile.read_option(:dev_environment)

    assert_match("Cluster #{cluster_name} deleted", Uffizzi.ui.last_message)
    assert(true, dev_environment_from_config.present?)
    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_delete_when_dev_not_exist
    error = assert_raises(MockShell::ExitError) do
      @dev.delete
    end

    assert_match('Uffizzi dev is not running', error.message)
  end
end
