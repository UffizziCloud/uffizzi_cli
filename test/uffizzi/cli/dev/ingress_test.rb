# frozen_string_literal: true

require 'test_helper'

class DevIngressTest < Minitest::Test
  def setup
    @ingress = Uffizzi::Cli::Dev::Ingress.new
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

  def test_open
    cluster_ingresses_get_body = json_fixture('files/uffizzi/uffizzi_cluster_ingresses.json')
    cluster_name = cluster_ingresses_get_body.dig(:cluster, :name)
    stubbed_get_cluster_ingresses_request = stub_get_cluster_ingresses_request(cluster_ingresses_get_body, @project_slug, cluster_name)

    config_path = '/skaffold.yaml'
    dev_environment = { name: cluster_name, config_path: config_path }
    Uffizzi::ConfigFile.write_option(:dev_environment, dev_environment)
    File.write(DevService.pid_path, @mock_process.pid)

    @ingress.open

    assert_requested(stubbed_get_cluster_ingresses_request)
    assert_match(cluster_ingresses_get_body[:ingresses].first, Uffizzi.ui.last_message)
  end
end
