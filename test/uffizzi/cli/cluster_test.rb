# frozen_string_literal: true

require 'psych'
require 'base64'
require 'test_helper'

class ClusterTest < Minitest::Test
  def setup
    @cluster = Uffizzi::Cli::Cluster.new
    @mock_prompt = MockPrompt.new
    Uffizzi.stubs(:prompt).returns(@mock_prompt)

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    ENV['GITHUB_OUTPUT'] = '/tmp/.env'
    ENV['GITHUB_ACTIONS'] = 'true'
    Uffizzi.ui.output_format = nil
    tmp_dir_name = (Time.now.utc.to_f * 100_000).to_i
    @kubeconfig_path = "/tmp/test/#{tmp_dir_name}/test-kubeconfig.yaml"
  end

  def teardown
    super

    File.delete(@kubeconfig_path) if File.exist?(@kubeconfig_path)
  end

  def test_create_cluster
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path)
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    @cluster.create

    created_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    kubeconfig_form_backend = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig)))

    assert_match('To update the current context', Uffizzi.ui.last_message)
    assert_equal(kubeconfig_form_backend, created_kubeconfig)
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_create_cluster_when_kubeconfig_already_exists
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path)
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    exists_kubeconfig = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig))).deep_dup
    exists_kubeconfig['users'][0]['name'] = 'another-user-name'
    exists_kubeconfig['clusters'][0]['name'] = 'another-cluster-name'
    exists_kubeconfig['contexts'][0]['name'] = 'another-context-name'
    exists_kubeconfig['contexts'][0]['context']['cluster'] = exists_kubeconfig['clusters'][0]['name']
    exists_kubeconfig['contexts'][0]['context']['user'] = exists_kubeconfig['users'][0]['name']
    exists_kubeconfig['current-context'] = exists_kubeconfig['clusters'][0]['name']

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, exists_kubeconfig.to_yaml)

    @cluster.create

    created_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    kubeconfig_form_backend = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig)))

    assert_equal(exists_kubeconfig['current-context'], created_kubeconfig['current-context'])
    assert_equal(2, created_kubeconfig['clusters'].count)
    assert_equal(2, created_kubeconfig['contexts'].count)
    assert_equal(2, created_kubeconfig['users'].count)
    assert_equal(exists_kubeconfig['clusters'][0]['name'], created_kubeconfig['clusters'][0]['name'])
    assert_equal(kubeconfig_form_backend['clusters'][0]['name'], created_kubeconfig['clusters'][1]['name'])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_create_cluster_with_flag_update_current_context_when_kubeconfig_already_exists
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path, 'update-current-context': true)
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    exists_kubeconfig = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig))).deep_dup
    exists_kubeconfig['users'][0]['name'] = 'another-user-name'
    exists_kubeconfig['clusters'][0]['name'] = 'another-cluster-name'
    exists_kubeconfig['contexts'][0]['name'] = 'another-context-name'
    exists_kubeconfig['contexts'][0]['context']['cluster'] = exists_kubeconfig['clusters'][0]['name']
    exists_kubeconfig['contexts'][0]['context']['user'] = exists_kubeconfig['users'][0]['name']
    exists_kubeconfig['current-context'] = exists_kubeconfig['clusters'][0]['name']

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, exists_kubeconfig.to_yaml)

    @cluster.create

    created_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    kubeconfig_form_backend = Psych.safe_load(Base64.decode64(cluster_get_body.dig(:cluster, :kubeconfig)))

    assert_equal(kubeconfig_form_backend['current-context'], created_kubeconfig['current-context'])
    assert_equal(2, created_kubeconfig['clusters'].count)
    assert_equal(2, created_kubeconfig['contexts'].count)
    assert_equal(2, created_kubeconfig['users'].count)
    assert_equal(exists_kubeconfig['clusters'][0]['name'], created_kubeconfig['clusters'][0]['name'])
    assert_equal(kubeconfig_form_backend['clusters'][0]['name'], created_kubeconfig['clusters'][1]['name'])
    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)

    previous_current_contexts = Uffizzi::ConfigFile.read_option(:previous_current_contexts)
    assert_equal(exists_kubeconfig['current-context'], previous_current_contexts.first[:current_context])
  end

  def test_list_clusters
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_clusters_list.json')
    stubbed_uffizzi_cluster_get_request = stub_uffizzi_get_clusters(clusters_get_body, @project_slug)

    @cluster.list

    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_list_clusters_with_all_flag
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_clusters_list_with_project_name.json')
    stubbed_uffizzi_cluster_get_request = stub_uffizzi_get_clusters(clusters_get_body, @project_slug)

    @cluster.list

    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_update_kubeconfig_if_kubeconfig_exists_with_another_cluster
    @cluster.options = command_options(kubeconfig: @kubeconfig_path)

    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    kubeconfig_from_backend = Psych.safe_load(Base64.decode64(cluster_get_body[:cluster][:kubeconfig]))

    kubeconfig_from_filesystem = kubeconfig_from_backend.deep_dup
    cluster_name_from_filesystem = 'filesystem_cluster_name'
    kubeconfig_from_filesystem['clusters'][0]['name'] = cluster_name_from_filesystem
    kubeconfig_from_filesystem['contexts'][0]['name'] = cluster_name_from_filesystem
    kubeconfig_from_filesystem['contexts'][0]['context']['cluster'] = cluster_name_from_filesystem
    kubeconfig_from_filesystem['contexts'][0]['context']['user'] = cluster_name_from_filesystem
    kubeconfig_from_filesystem['users'][0]['name'] = cluster_name_from_filesystem
    kubeconfig_from_filesystem['current-context'] = cluster_name_from_filesystem

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, kubeconfig_from_filesystem.to_yaml)

    @cluster.update_kubeconfig('cluster_name')

    assert_requested(stubbed_uffizzi_cluster_get_request)

    updated_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    assert_equal(2, updated_kubeconfig['clusters'].size)
    assert_equal(2, updated_kubeconfig['contexts'].size)
    assert_equal(2, updated_kubeconfig['users'].size)
    assert_equal(kubeconfig_from_backend['current-context'], updated_kubeconfig['current-context'])

    previous_current_contexts = Uffizzi::ConfigFile.read_option(:previous_current_contexts)
    assert_equal(kubeconfig_from_filesystem['current-context'], previous_current_contexts.first[:current_context])
  end

  def test_update_kubeconfig_if_kubeconfig_exists_with_same_cluster_but_another_values
    @cluster.options = command_options(kubeconfig: @kubeconfig_path)

    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    kubeconfig_from_backend = Psych.safe_load(Base64.decode64(cluster_get_body[:cluster][:kubeconfig]))

    kubeconfig_from_filesystem = kubeconfig_from_backend.deep_dup
    kubeconfig_from_filesystem['clusters'][0]['cluster']['server'] = 'old_cluster_service'
    kubeconfig_from_filesystem['clusters'][0]['cluster']['certificate-authority-data'] = 'some_cert'
    kubeconfig_from_filesystem['contexts'][0]['name'] = 'old_context_name'
    kubeconfig_from_filesystem['contexts'][0]['context']['user'] = 'old_user_name'
    kubeconfig_from_filesystem['users'][0]['name'] = 'old_user_name'

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, kubeconfig_from_filesystem.to_yaml)

    @cluster.update_kubeconfig('cluster_name')

    assert_requested(stubbed_uffizzi_cluster_get_request)

    updated_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    assert_equal(1, updated_kubeconfig['clusters'].size)
    assert_equal(1, updated_kubeconfig['contexts'].size)
    assert_equal(1, updated_kubeconfig['users'].size)
    assert_equal(kubeconfig_from_backend['clusters'][0]['cluster']['server'], updated_kubeconfig['clusters'][0]['cluster']['server'])
    assert_equal(kubeconfig_from_backend['clusters'][0]['cluster']['certificate-authority-data'],
                 updated_kubeconfig['clusters'][0]['cluster']['certificate-authority-data'])
    assert_equal(kubeconfig_from_backend['contexts'][0]['name'], updated_kubeconfig['contexts'][0]['name'])
    assert_equal(kubeconfig_from_backend['contexts'][0]['context']['user'], updated_kubeconfig['contexts'][0]['context']['user'])
    assert_equal(kubeconfig_from_backend['users'][0]['name'], updated_kubeconfig['users'][0]['name'])
  end

  def test_update_kubeconfig_if_kubeconfig_option_is_empty
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    kubeconfig_from_backend = Psych.safe_load(Base64.decode64(cluster_get_body[:cluster][:kubeconfig]))

    @cluster.update_kubeconfig('cluster_name')

    new_file = File.expand_path(Uffizzi.configuration.default_kubeconfig_path)
    kubeconfig_from_file = Psych.safe_load(File.read(new_file))

    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_equal(kubeconfig_from_backend['clusters'][0]['name'], kubeconfig_from_file['clusters'][0]['name'])

    File.delete(new_file)
  end

  def test_update_kubeconfig_if_kubeconfig_is_empty_and_cluster_is_deploying
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    stub_get_cluster_request(cluster_get_body, @project_slug)

    error = assert_raises(MockShell::ExitError) do
      @cluster.update_kubeconfig('cluster_name')
    end

    assert_match('is empty', error.message)
  end

  def test_update_kubeconfig_if_kubeconfig_is_empty_and_cluster_is_failed
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_failed.json')
    stub_get_cluster_request(cluster_get_body, @project_slug)

    error = assert_raises(MockShell::ExitError) do
      @cluster.update_kubeconfig('cluster_name')
    end

    assert_match('is empty', error.message)
  end

  def test_update_kubeconfig_if_kubeconfig_path_has_invalid_file
    @cluster.options = command_options(kubeconfig: @kubeconfig_path)

    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    kubeconfig_from_filesystem = 'some data'

    FileUtils.mkdir_p(File.dirname(@kubeconfig_path))
    File.write(@kubeconfig_path, kubeconfig_from_filesystem)

    error = assert_raises(KubeconfigService::InvalidKubeconfigError) do
      @cluster.update_kubeconfig('cluster_name')
    end

    assert_requested(stubbed_uffizzi_cluster_get_request)
    assert_match('Invalid kubeconfig', error.message)
  end

  def test_describe_cluster
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(clusters_get_body, @project_slug)

    @cluster.describe('cluster-name')

    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_delete_cluster
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    @cluster.delete('cluster-name')

    assert_requested(stubbed_uffizzi_cluster_delete_request)
  end

  def test_delete_cluster_with_flag_delete_config_and_single_cluster_in_kubeconfig
    @cluster.options = command_options('delete-config' => true)
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    clusters_config = [{ id: clusters_get_body[:cluster][:id], kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)
    Uffizzi::ConfigFile.write_option(:clusters, clusters_config)

    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(clusters_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    @cluster.delete('cluster-name')

    kubeconfig_after_exclude = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_empty(kubeconfig_after_exclude['clusters'])
    assert_empty(kubeconfig_after_exclude['contexts'])
    assert_empty(kubeconfig_after_exclude['users'])
    assert_nil(kubeconfig_after_exclude['current-context'])
    assert_requested(stubbed_uffizzi_cluster_delete_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_delete_cluster_with_flag_delete_config_and_multiply_clusters_in_kubeconfig
    @cluster.options = command_options('delete-config' => true)
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    clusters_config = [{ id: clusters_get_body[:cluster][:id], kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]

    another_cluster = kubeconfig['clusters'][0].deep_dup
    another_context = kubeconfig['contexts'][0].deep_dup
    another_user = kubeconfig['users'][0].deep_dup
    another_cluster['name'] = 'another-cluster-name'
    another_user['name'] = 'another-user-name'
    another_context['name'] = 'another-context-name'
    another_context['context']['cluster'] = another_cluster['name']
    another_context['context']['user'] = another_user['name']

    kubeconfig['clusters'] << another_cluster
    kubeconfig['contexts'] << another_context
    kubeconfig['users'] << another_user

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)
    Uffizzi::ConfigFile.write_option(:clusters, clusters_config)

    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(clusters_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    @cluster.delete('cluster-name')

    kubeconfig_after_exclude = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_equal(1, kubeconfig_after_exclude['clusters'].count)
    assert_equal(1, kubeconfig_after_exclude['contexts'].count)
    assert_equal(1, kubeconfig_after_exclude['users'].count)
    assert_equal(another_context['name'], kubeconfig_after_exclude['current-context'])
    assert_requested(stubbed_uffizzi_cluster_delete_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_delete_cluster_with_flag_delete_config_and_kubeconfig_file_not_exists
    @cluster.options = command_options('delete-config' => true)
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    clusters_config = [{ id: clusters_get_body[:cluster][:id], kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]

    Uffizzi::ConfigFile.write_option(:clusters, clusters_config)

    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(clusters_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    @cluster.delete('cluster-name')

    assert_match('Warning', Uffizzi.ui.last_message)
    refute(File.exist?(Uffizzi.configuration.default_kubeconfig_path))
    assert_requested(stubbed_uffizzi_cluster_delete_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_delete_cluster_with_flag_delete_config_and_kubeconfig_file_has_empty_clusters
    @cluster.options = command_options('delete-config' => true)
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    clusters_config = [{ id: clusters_get_body[:cluster][:id], kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    kubeconfig['clusters'] = []
    kubeconfig['contexts'] = []
    kubeconfig['users'] = []

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)
    Uffizzi::ConfigFile.write_option(:clusters, clusters_config)

    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(clusters_get_body, @project_slug)
    stubbed_uffizzi_cluster_delete_request = stub_uffizzi_delete_cluster(@project_slug)

    @cluster.delete('cluster-name')

    kubeconfig_after_exclude = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_empty(kubeconfig_after_exclude['clusters'])
    assert_empty(kubeconfig_after_exclude['contexts'])
    assert_empty(kubeconfig_after_exclude['users'])
    assert_nil(kubeconfig_after_exclude['current-context'])
    assert_requested(stubbed_uffizzi_cluster_delete_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_disconnect_cluster_with_existing_previous_current_context
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    prev_current_context = 'prev-context'
    kubeconfig['clusters'] << { 'name' => prev_current_context }
    kubeconfig['contexts'] << { 'name' => prev_current_context }
    clusters_config = [{ current_context: prev_current_context, kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)
    Uffizzi::ConfigFile.write_option(:previous_current_contexts, clusters_config)

    @cluster.disconnect

    kubeconfig_after_disconnect = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_equal(2, kubeconfig_after_disconnect['clusters'].count)
    assert_equal(2, kubeconfig_after_disconnect['contexts'].count)
    assert_equal(prev_current_context, kubeconfig_after_disconnect['current-context'])
  end

  def test_disconnect_cluster_without_previous_current_context_should_ask_question
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    prev_current_context = 'prev-context'
    kubeconfig['clusters'] << { 'name' => prev_current_context }
    kubeconfig['contexts'] << { 'name' => prev_current_context }

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)

    @mock_prompt.promise_question_answer('Select origin context to switch on:', :first)

    @cluster.disconnect

    kubeconfig_after_disconnect = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_equal(2, kubeconfig_after_disconnect['clusters'].count)
    assert_equal(2, kubeconfig_after_disconnect['contexts'].count)
    assert_equal(prev_current_context, kubeconfig_after_disconnect['current-context'])
  end

  def test_disconnect_cluster_without_previous_current_context_in_kubeconfig_should_ask_question
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_cluster_describe.json')
    kubeconfig = Psych.safe_load(Base64.decode64(clusters_get_body[:cluster][:kubeconfig]))
    prev_current_context = 'prev-context'
    kubeconfig['clusters'] << { 'name' => prev_current_context }
    kubeconfig['contexts'] << { 'name' => prev_current_context }
    clusters_config = [{ current_context: 'none-existing-context', kubeconfig_path: Uffizzi.configuration.default_kubeconfig_path }]

    FileUtils.mkdir_p(File.dirname(Uffizzi.configuration.default_kubeconfig_path))
    File.write(Uffizzi.configuration.default_kubeconfig_path, kubeconfig.to_yaml)
    Uffizzi::ConfigFile.write_option(:previous_current_contexts, clusters_config)

    @mock_prompt.promise_question_answer('Select origin context to switch on:', :first)

    @cluster.disconnect

    kubeconfig_after_disconnect = Psych.safe_load(File.read(Uffizzi.configuration.default_kubeconfig_path))

    assert_equal(2, kubeconfig_after_disconnect['clusters'].count)
    assert_equal(2, kubeconfig_after_disconnect['contexts'].count)
    assert_equal(prev_current_context, kubeconfig_after_disconnect['current-context'])
  end
end
