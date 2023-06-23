# frozen_string_literal: true

require 'psych'
require 'base64'
require 'test_helper'

class ClusterTest < Minitest::Test
  def setup
    @cluster = Uffizzi::Cli::Cluster.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    ENV['GITHUB_OUTPUT'] = '/tmp/.env'
    ENV['GITHUB_ACTIONS'] = 'true'
    Uffizzi.ui.output_format = nil
    @kubeconfig_path = './test-kubeconfig.yaml'
    File.delete(@kubeconfig_path) if File.exist?(@kubeconfig_path)
  end

  def test_create_cluster_success
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path)
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_deploying.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    File.stubs(:write).returns(100)

    @cluster.create

    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_create_cluster_if_path_already_exists
    File.stubs(:exists?).returns(true)
    @cluster.options = command_options(name: 'test-cluster', kubeconfig: './kubeconfig.json')

    assert_raises(Uffizzi::Error) do
      @cluster.create
    end
  end

  def test_list_clusters
    clusters_get_body = json_fixture('files/uffizzi/uffizzi_clusters_list.json')
    stubbed_uffizzi_cluster_get_request = stub_uffizzi_get_clusters(clusters_get_body, @project_slug)

    @cluster.list

    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  def test_update_kubeconfig_if_kubeconfig_exists_with_another_cluster
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path)

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

    File.write(@kubeconfig_path, kubeconfig_from_filesystem.to_yaml)

    @cluster.update_kubeconfig

    assert_requested(stubbed_uffizzi_cluster_get_request)

    updated_kubeconfig = Psych.safe_load(File.read(@kubeconfig_path))
    assert_equal(2, updated_kubeconfig['clusters'].size)
    assert_equal(2, updated_kubeconfig['contexts'].size)
    assert_equal(2, updated_kubeconfig['users'].size)
  end

  def test_update_kubeconfig_if_kubeconfig_exists_with_same_cluster_but_another_values
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @kubeconfig_path)

    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
    kubeconfig_from_backend = Psych.safe_load(Base64.decode64(cluster_get_body[:cluster][:kubeconfig]))

    kubeconfig_from_filesystem = kubeconfig_from_backend.deep_dup
    kubeconfig_from_filesystem['clusters'][0]['cluster']['server'] = 'old_cluster_service'
    kubeconfig_from_filesystem['clusters'][0]['cluster']['certificate-authority-data'] = 'some_cert'
    kubeconfig_from_filesystem['contexts'][0]['name'] = 'old_context_name'
    kubeconfig_from_filesystem['contexts'][0]['context']['user'] = 'old_user_name'
    kubeconfig_from_filesystem['users'][0]['name'] = 'old_user_name'

    File.write(@kubeconfig_path, kubeconfig_from_filesystem.to_yaml)

    @cluster.update_kubeconfig

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
end
