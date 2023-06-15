# frozen_string_literal: true

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
    @config_path = './test-kubeconfig.json'
    File.delete(@config_path) if File.exist?(@config_path)
  end

  def test_create_cluster_success
    @cluster.options = command_options(name: 'test-cluster', kubeconfig: @config_path)
    cluster_create_body = json_fixture('files/uffizzi/uffizzi_cluster_not_ready.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(cluster_create_body, @project_slug)
    cluster_get_body = json_fixture('files/uffizzi/uffizzi_cluster_ready.json')
    stubbed_uffizzi_cluster_get_request = stub_get_cluster_request(cluster_get_body, @project_slug)

    File.stubs(:write).returns(100)

    @cluster.create

    assert_requested(stubbed_uffizzi_cluster_create_request)
    assert_requested(stubbed_uffizzi_cluster_get_request)
  end

  # def test_create_cluster_if_path_already_exists
  #   File.stubs(:exists?).returns(true)
  #   @cluster.options = command_options(name: 'test-cluster', kubeconfig: './kubeconfig.json')

  #   assert_raises(Uffizzi::Error) do
  #     @cluster.create
  #   end
  # end
end
