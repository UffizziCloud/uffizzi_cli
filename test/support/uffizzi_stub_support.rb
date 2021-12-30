# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziStubSupport
  include ApiRoutes

  def stub_uffizzi_login(base_url, status, body, headers)
    url = session_uri(base_url)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_logout(base_url, status, headers)
    url = session_uri(base_url)

    stub_request(:delete, url).to_return(status: status, body: '', headers: headers)
  end

  def stub_uffizzi_projects(base_url, status, body, headers)
    url = projects_uri(base_url)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_create_compose(base_url, status, body, headers)
    url = compose_files_uri(base_url)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_create_deployment(base_url, project_id, status, body, headers)
    url = deployments_uri(base_url, project_id)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_deploy_containers(base_url, project_id, deployment_id, status, body, headers)
    url = deploy_containers_uri(base_url, project_id, deployment_id)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end
end
