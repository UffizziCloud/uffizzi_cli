# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziStubSupport
  include ApiRoutes

  def stub_uffizzi_login_success(body)
    url = session_uri(Uffizzi.configuration.server)
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }

    stub_request(:post, url).to_return(status: 201, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_login_failed(body)
    url = session_uri(Uffizzi.configuration.server)

    stub_request(:post, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_logout
    url = session_uri(Uffizzi.configuration.server)
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }

    stub_request(:delete, url).to_return(status: 204, body: '', headers: headers)
  end

  def stub_uffizzi_projects_success(body)
    url = projects_uri(Uffizzi.configuration.server)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_projects_failed(body)
    url = projects_uri(Uffizzi.configuration.server)

    stub_request(:get, url).to_return(status: 401, body: body.to_json)
  end

  def stub_uffizzi_create_compose(base_url, status, body, headers)
    url = compose_files_uri(base_url)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_create_deployment(base_url, status, body, headers)
    url = deployments_uri(base_url)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_project_secret_list(body, project_slug)
    url = secrets_uri(Uffizzi.configuration.server, project_slug)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_project_secret_create(body, project_slug)
    url = "#{secrets_uri(Uffizzi.configuration.server, project_slug)}/bulk_create"

    stub_request(:post, url).to_return(status: 201, body: body.to_json)
  end

  def stub_uffizzi_project_secret_delete(project_slug, secret_id)
    url = secret_uri(Uffizzi.configuration.server, project_slug, secret_id)

    stub_request(:delete, url).to_return(status: 204, body: '')
  end

  def stub_uffizzi_create_credential(body)
    uri = credentials_uri(Uffizzi.configuration.server)

    stub_request(:post, uri).to_return(status: 201, body: body.to_json)
  end

  def stub_uffizzi_create_credential_fail(body)
    uri = credentials_uri(Uffizzi.configuration.server)

    stub_request(:post, uri).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_delete_credential(credential_type)
    uri = delete_credential_uri(Uffizzi.configuration.server, credential_type)

    stub_request(:delete, uri).to_return(status: 204)
  end

  def stub_uffizzi_delete_credential_fail(body, credential_type)
    uri = delete_credential_uri(Uffizzi.configuration.server, credential_type)

    stub_request(:delete, uri).to_return(status: 422, body: body.to_json)
  end
end
