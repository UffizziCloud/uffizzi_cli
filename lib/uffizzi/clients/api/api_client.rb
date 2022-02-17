# frozen_string_literal: true

require_relative 'api_routes'
require_relative 'http_client'

module ApiClient
  include ApiRoutes
  def create_session(hostname, params = {})
    uri = session_uri(hostname)
    response = Uffizzi::HttpClient.make_post_request(uri, params, false)

    build_response(response)
  end

  def destroy_session(hostname)
    uri = session_uri(hostname)
    response = Uffizzi::HttpClient.make_delete_request(uri)

    build_response(response)
  end

  def fetch_projects(hostname)
    uri = projects_uri(hostname)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def set_compose_file(hostname, params, project_slug)
    uri = compose_file_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_post_request(uri, params)

    build_response(response)
  end

  def unset_compose_file(hostname, project_slug)
    uri = compose_file_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_delete_request(uri, true)

    build_response(response)
  end

  def bulk_create_secrets(hostname, project_slug, params)
    uri = secrets_uri(hostname, project_slug) + '/bulk_create'
    response = Uffizzi::HttpClient.make_post_request(uri, true, params)

    build_response(response)
  end

  def delete_secret(hostname, project_slug, id)
    uri = secret_uri(hostname, project_slug, id)
    response = Uffizzi::HttpClient.make_delete_request(uri, true)

    build_response(response)
  end

  def describe_compose_file(hostname, project_slug)
    uri = compose_file_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def validate_compose_file(hostname, project_slug)
    uri = validate_compose_file_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def fetch_deployments(hostname, project_slug)
    uri = deployments_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def create_deployment(hostname, project_slug, params)
    uri = deployments_uri(hostname, project_slug)
    response = Uffizzi::HttpClient.make_post_request(uri, params)

    build_response(response)
  end

  def delete_deployment(hostname, project_slug, deployment_id)
    uri = deployment_uri(hostname, project_slug, deployment_id)
    response = Uffizzi::HttpClient.make_delete_request(uri, true)

    build_response(response)
  end

  def describe_deployment(hostname, project_slug, deployment_id)
    uri = deployment_uri(hostname, project_slug, deployment_id)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def get_activity_items(hostname, project_slug, deployment_id)
    uri = activity_items_uri(hostname, project_slug, deployment_id)
    response = Uffizzi::HttpClient.make_get_request(uri)

    build_response(response)
  end

  def deploy_containers(hostname, project_slug, deployment_id, params)
    uri = deploy_containers_uri(hostname, project_slug, deployment_id)
    response = Uffizzi::HttpClient.make_post_request(uri, params)

    build_response(response)
  end

  def print_errors(errors)
    puts errors.keys.reduce([]) { |acc, key| acc.push(errors[key]) }
  end

  private

  def build_response(response)
    {
      body: response_body(response),
      headers: response_cookie(response),
      code: response.class,
    }
  end

  def response_body(response)
    return nil if response.body.nil?

    JSON.parse(response.body, symbolize_names: true)
  end

  def response_cookie(response)
    cookies = response.to_hash['set-cookie']
    return nil if cookies.nil?

    cookie_content = cookies.first
    cookie = cookie_content.split(';').first
    Uffizzi::ConfigFile.rewrite_cookie(cookie) if Uffizzi::ConfigFile.exists?

    cookie
  end
end
