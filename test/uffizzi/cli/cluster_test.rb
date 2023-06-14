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
  end

  def test_create_cluster_success
    @cluster.options = command_options(name: 'test-cluster', kubeconfig: './kubeconfig.json')
    create_body = json_fixture('files/uffizzi/uffizzi_create_cluster_success.json')
    stubbed_uffizzi_cluster_create_request = stub_uffizzi_create_cluster(create_body, @project_slug)

    @cluster.create

    assert_requested(stubbed_uffizzi_cluster_create_request)
  end

  def test_create_cluster_if_path_already_exists
    File.stubs(:exists?).returns(true)
    @cluster.options = command_options(name: 'test-cluster', kubeconfig: './kubeconfig.json')

    assert_raises(Uffizzi::Error) do
      @cluster.create
    end
  end
end
