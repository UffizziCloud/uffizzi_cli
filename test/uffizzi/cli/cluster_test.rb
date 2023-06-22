# frozen_string_literal: true

require 'test_helper'
require 'fakefs/safe'
require 'byebug'

class ClusterTest < Minitest::Test
  def setup
    @cluster = Uffizzi::Cli::Cluster.new
    # config = File.expand_path('../../test', __FILE__)
    # FakeFS::FileSystem.clone(config)
    # puts Dir.pwd

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
    ENV['GITHUB_OUTPUT'] = '/tmp/.env'
    ENV['GITHUB_ACTIONS'] = 'true'
    Uffizzi.ui.output_format = nil
    @config_path = './test-kubeconfig.json'
    File.delete(@config_path) if File.exist?(@config_path)
  end

  def test_create_cluster_success
    @cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @config_path)
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

  # def test_update_kubeconfig
  #   FakeFS.activate!
  #   fs = File.expand_path('../../..', __FILE__)
  #   FakeFS::FileSystem.clone(fs)
  #   cluster = Uffizzi::Cli::Cluster.new
  #   sign_in
  #   Uffizzi::ConfigFile.write_option(:project, 'dbp')
  #   Uffizzi.ui.output_format = nil

  #   cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_deployed.json')
  #   stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)
  #   cluster.options = command_options(name: 'uffizzi-test-cluster', kubeconfig: @config_path)

  #   cluster.update_kubeconfig

  #   assert_requested(stubbed_uffizzi_cluster_get_request)
  #   FakeFS.deactivate!
  # end
end
