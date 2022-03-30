# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziPreviewStubSupport
  include ApiRoutes

  def stub_uffizzi_preview_list(base_url, status, body, headers, project_slug)
    url = deployments_uri(base_url, project_slug)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_delete(base_url, status, body, headers, project_slug, deployment_id)
    url = deployment_uri(base_url, project_slug, deployment_id)

    stub_request(:delete, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_create(base_url, status, body, headers, project_slug)
    url = deployments_uri(base_url, project_slug)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_describe(base_url, status, body, headers, project_slug, deployment_id)
    url = deployment_uri(base_url, project_slug, deployment_id)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_deploy_containers(base_url, status, body, headers, project_slug, deployment_id)
    url = deploy_containers_uri(base_url, project_slug, deployment_id)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_activity_items(base_url, status, body, headers, project_slug, deployment_id)
    url = activity_items_uri(base_url, project_slug, deployment_id)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_preview_events_success(body, deployment_id, project_slug)
    url = events_uri(Uffizzi.configuration.hostname, project_slug, deployment_id)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_preview_services_list(body, project_slug, deployment_id)
    url = preview_services_uri(Uffizzi.configuration.hostname, project_slug, deployment_id)

    stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
  end

  def stub_uffizzi_preview_service_logs(body, project_slug, deployment_id, container_name)
    url = preview_service_logs_uri(Uffizzi.configuration.hostname, project_slug, deployment_id, container_name)

    stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
  end
end
