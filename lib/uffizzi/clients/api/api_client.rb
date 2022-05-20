# frozen_string_literal: true

require_relative 'api_routes'
require_relative 'http_client'

module ApiClient
  include ApiRoutes

  def create_session(server, params = {})
    uri = session_uri(server)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def destroy_session(server)
    uri = session_uri(server)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def fetch_projects(server)
    uri = projects_uri(server)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_credentials(server)
    uri = credentials_uri(server)

    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def check_credential(server, type)
    uri = check_credential_uri(server, type)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def describe_project(server, project_slug)
    uri = project_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def create_project(server, params)
    uri = projects_uri(server)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def delete_project(server, project_slug)
    uri = project_uri(server, project_slug)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def create_credential(server, params)
    uri = credentials_uri(server)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def fetch_deployment_services(server, project_slug, deployment_id)
    uri = preview_services_uri(server, project_slug, deployment_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def delete_credential(server, credential_type)
    uri = delete_credential_uri(server, credential_type)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def fetch_deployment_service_logs(server, project_slug, deployment_id, container_name)
    uri = preview_service_logs_uri(server, project_slug, deployment_id, container_name)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def set_compose_file(server, params, project_slug)
    uri = compose_file_uri(server, project_slug)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def unset_compose_file(server, project_slug)
    uri = compose_file_uri(server, project_slug)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def fetch_secrets(server, project_slug)
    uri = secrets_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def bulk_create_secrets(server, project_slug, params)
    uri = "#{secrets_uri(server, project_slug)}/bulk_create"
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def delete_secret(server, project_slug, id)
    uri = secret_uri(server, project_slug, id)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def describe_compose_file(server, project_slug)
    uri = compose_file_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def validate_compose_file(server, project_slug)
    uri = validate_compose_file_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_deployments(server, project_slug)
    uri = deployments_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def create_deployment(server, project_slug, params)
    uri = deployments_uri(server, project_slug)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def update_deployment(server, project_slug, deployment_id, params)
    uri = deployment_uri(server, project_slug, deployment_id)
    response = http_client.make_put_request(uri, params)

    build_response(response)
  end

  def delete_deployment(server, project_slug, deployment_id)
    uri = deployment_uri(server, project_slug, deployment_id)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def describe_deployment(server, project_slug, deployment_id)
    uri = deployment_uri(server, project_slug, deployment_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_events(server, project_slug, deployment_id)
    uri = events_uri(server, project_slug, deployment_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def get_activity_items(server, project_slug, deployment_id)
    uri = activity_items_uri(server, project_slug, deployment_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def deploy_containers(server, project_slug, deployment_id, params)
    uri = deploy_containers_uri(server, project_slug, deployment_id)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  private

  def http_client
    if @http_client.nil?
      params = {}
      if Uffizzi::ConfigFile.exists?
        params[:cookie] = Uffizzi::ConfigFile.read_option(:cookie)
        params[:basic_auth_user] = Uffizzi::ConfigFile.read_option(:basic_auth_user)
        params[:basic_auth_password] = Uffizzi::ConfigFile.read_option(:basic_auth_password)
      end

      @http_client = Uffizzi::HttpClient.new(params[:cookie], params[:basic_auth_user], params[:basic_auth_password])
    end

    @http_client
  end

  def build_response(response)
    {
      body: response_body(response),
      headers: response_cookie(response),
      code: response.class,
    }
  end

  def response_body(response)
    return nil if response.body.nil? || response.body.empty?

    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError
    raise Uffizzi::Error.new(response.message)
  end

  def response_cookie(response)
    cookies = response.to_hash['set-cookie']
    return nil if cookies.nil?

    cookie_content = cookies.first
    cookie = cookie_content.split(';').first
    Uffizzi::ConfigFile.rewrite_cookie(cookie) if Uffizzi::ConfigFile.exists? && Uffizzi::ConfigFile.option_has_value?(:cookie)
    http_client.auth_cookie = cookie

    cookie
  end
end
