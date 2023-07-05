# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziStubSupport
  include ApiRoutes

  def stub_uffizzi_login_success(body)
    url = session_uri(Uffizzi.configuration.server)
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }

    stub_request(:post, url).to_return(status: 201, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_login_by_identity_token_success(body)
    url = ci_session_uri(Uffizzi.configuration.server)
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }

    stub_request(:post, url).to_return(status: 201, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_login_failed(body)
    url = session_uri(Uffizzi.configuration.server)

    stub_request(:post, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_login_by_identity_token_failure(body)
    url = ci_session_uri(Uffizzi.configuration.server)

    stub_request(:post, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_logout
    url = session_uri(Uffizzi.configuration.server)
    headers = { "set-cookie": '_uffizzi=test; path=/; HttpOnly' }

    stub_request(:delete, url).to_return(status: 204, body: '', headers: headers)
  end

  def stub_uffizzi_accounts_success(body)
    url = accounts_uri(Uffizzi.configuration.server)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_account_success(body, account_name)
    url = account_uri(Uffizzi.configuration.server, account_name)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_account_projects_success(body, account_id)
    url = account_projects_uri(Uffizzi.configuration.server, account_id)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_account_projects_failed(body, account_id)
    url = account_projects_uri(Uffizzi.configuration.server, account_id)

    stub_request(:get, url).to_return(status: 401, body: body.to_json)
  end

  def stub_uffizzi_projects_success(body)
    url = projects_uri(Uffizzi.configuration.server)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_project_success(body, project_slug)
    url = project_uri(Uffizzi.configuration.server, project_slug)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_project_failed(body, project_slug)
    url = project_uri(Uffizzi.configuration.server, project_slug)

    stub_request(:get, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_project_create_success(body, account_id)
    url = create_projects_uri(Uffizzi.configuration.server, account_id)

    stub_request(:post, url).to_return(status: 201, body: body.to_json)
  end

  def stub_uffizzi_project_delete_success(body, project_slug)
    url = project_uri(Uffizzi.configuration.server, project_slug)

    stub_request(:delete, url).to_return(status: 204, body: body.to_json)
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

  def stub_uffizzi_create_credential(account_id, body)
    uri = credentials_uri(Uffizzi.configuration.server, account_id)

    stub_request(:post, uri).to_return(status: 201, body: body.to_json)
  end

  def stub_uffizzi_update_credential(account_id, body, type)
    uri = credential_uri(Uffizzi.configuration.server, account_id, type)

    stub_request(:put, uri).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_check_credential_success(account_id, type)
    uri = check_credential_uri(Uffizzi.configuration.server, account_id, type)

    stub_request(:get, uri).to_return(status: 200, body: '')
  end

  def stub_uffizzi_check_credential_fail(account_id, type)
    uri = check_credential_uri(Uffizzi.configuration.server, account_id, type)

    stub_request(:get, uri).to_return(status: 422, body: '')
  end

  def stub_uffizzi_list_credentials(account_id, body)
    uri = credentials_uri(Uffizzi.configuration.server, account_id)

    stub_request(:get, uri).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_create_credential_fail(account_id, body)
    uri = credentials_uri(Uffizzi.configuration.server, account_id)

    stub_request(:post, uri).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_delete_credential(account_id, credential_type)
    uri = credential_uri(Uffizzi.configuration.server, account_id, credential_type)

    stub_request(:delete, uri).to_return(status: 204)
  end

  def stub_uffizzi_delete_credential_fail(account_id, body, credential_type)
    uri = credential_uri(Uffizzi.configuration.server, account_id, credential_type)

    stub_request(:delete, uri).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_create_cluster(body, project_slug)
    uri = clusters_uri(Uffizzi.configuration.server, project_slug)
    stub_request(:post, uri).to_return(status: 201, body: body.to_json)
  end

  def stub_get_cluster_request(body, project_slug)
    uri = cluster_uri(Uffizzi.configuration.server, project_slug, nil)
    uri = %r{#{uri}([A-Za-z0-9\-_]+)}

    stub_request(:get, uri).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_get_clusters(body, project_slug)
    uri = clusters_uri(Uffizzi.configuration.server, project_slug)
    stub_request(:get, uri).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_delete_cluster(project_slug)
    uri = cluster_uri(Uffizzi.configuration.server, project_slug, nil)
    uri = %r{#{uri}([A-Za-z0-9\-_]+)}

    stub_request(:delete, uri).to_return(status: 204)
  end

  def stub_get_token_request(body)
    uri = %r{#{Uffizzi.configuration.server}/api/cli/v1/access_tokens/([A-Za-z0-9\-_]+)}

    stub_request(:get, uri).to_return(status: 200, body: body.to_json)
  end

  def stub_create_token_request(body)
    uri = "#{Uffizzi.configuration.server}/api/cli/v1/access_tokens"

    stub_request(:post, uri).to_return(status: 201, body: body.to_json)
  end
end
