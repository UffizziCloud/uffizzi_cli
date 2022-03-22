# frozen_string_literal: true

require 'test_helper'

class ServiceTest < Minitest::Test
  def setup
    @service = Uffizzi::CLI::Preview::Service.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'dbp')
    @project_slug = Uffizzi::ConfigFile.read_option(:project)
  end

  def test_list_preview_services
    body = json_fixture('files/uffizzi/uffizzi_preview_services_list.json')
    deployment_id = 318
    stubbed_uffizzi_preview_services_list = stub_uffizzi_preview_services_list(body, @project_slug, deployment_id)

    @service.list("deployment-#{deployment_id}")

    assert_requested(stubbed_uffizzi_preview_services_list)
  end

  def test_list_preview_service_logs
    body = json_fixture('files/uffizzi/uffizzi_preview_service_logs_success.json')
    container_name = 'redis'
    deployment_id = 318
    params = {
      project_slug: @project_slug,
      deployment_id: deployment_id,
      container_name: container_name,
    }
    stubbed_uffizzi_preview_service_logs = stub_uffizzi_preview_service_logs(Uffizzi.configuration.hostname, 200, body, {}, params)

    @service.logs('container', "deployment-#{deployment_id}", container_name)

    assert_requested(stubbed_uffizzi_preview_service_logs)
  end
end
