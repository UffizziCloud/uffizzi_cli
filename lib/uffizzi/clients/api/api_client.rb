# frozen_string_literal: true

require_relative 'api_routes'
require_relative 'http_client'

module ApiClient
  class ResponseError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response

      super(response.to_s)
    end
  end

  include ApiRoutes

  def create_session(server, params = {})
    uri = session_uri(server)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def create_ci_session(server, params = {})
    uri = ci_session_uri(server)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def destroy_session(server)
    uri = session_uri(server)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def fetch_accounts(server)
    uri = accounts_uri(server)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def check_can_install(server, account_id)
    uri = account_can_install_uri(server, account_id)

    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_projects(server)
    uri = projects_uri(server)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_account_projects(server, account_id)
    uri = account_projects_uri(server, account_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_credentials(server, account_id)
    uri = credentials_uri(server, account_id)

    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def check_credential(server, account_id, type)
    uri = check_credential_uri(server, account_id, type)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_project(server, project_slug)
    uri = project_uri(server, project_slug)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def fetch_account(server, account_name)
    uri = account_uri(server, account_name)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def update_account(server, account_name, params)
    uri = account_uri(server, account_name)
    response = http_client.make_put_request(uri, params)

    build_response(response)
  end

  def create_project(server, account_id, params)
    uri = create_projects_uri(server, account_id)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def delete_project(server, project_slug)
    uri = project_uri(server, project_slug)
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def create_credential(server, account_id, params)
    uri = credentials_uri(server, account_id)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def update_credential(server, account_id, params, type)
    uri = credential_uri(server, account_id, type)
    response = http_client.make_put_request(uri, params)

    build_response(response)
  end

  def fetch_deployment_services(server, project_slug, deployment_id)
    uri = preview_services_uri(server, project_slug, deployment_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def delete_credential(server, account_id, credential_type)
    uri = credential_uri(server, account_id, credential_type)
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

  def fetch_deployments(server, project_slug, filter)
    uri = deployments_uri(server, project_slug, filter)
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

  def get_k8s_container_description(server, project_slug, deployment_id, container_name)
    uri = k8s_container_description_uri(server, project_slug, deployment_id, container_name)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def get_project_clusters(server, project_slug, params = nil)
    uri = project_clusters_uri(server, project_slug, oidc_token: params[:oidc_token])
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def create_cluster(server, project_slug, params)
    uri = project_clusters_uri(server, project_slug, oidc_token: nil)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def scale_down_cluster(server, project_slug, cluster_name)
    uri = scale_down_cluster_uri(server, project_slug, cluster_name)
    response = http_client.make_put_request(uri)

    build_response(response)
  end

  def scale_up_cluster(server, project_slug, cluster_name)
    uri = scale_up_cluster_uri(server, project_slug, cluster_name)
    response = http_client.make_put_request(uri)

    build_response(response)
  end

  def sync_cluster(server, project_slug, cluster_name)
    uri = sync_cluster_uri(server, project_slug, cluster_name)
    response = http_client.make_put_request(uri)

    build_response(response)
  end

  def create_access_token(server, session_id)
    uri = access_tokens_url(server)

    params = { session_id: session_id }

    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def get_cluster(server, project_slug, params)
    uri = cluster_uri(server, project_slug, cluster_name: params[:cluster_name], oidc_token: params[:oidc_token])
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def get_cluster_ingresses(server, project_slug, params)
    uri = project_cluster_ingresses_uri(server, project_slug, cluster_name: params[:cluster_name], oidc_token: params[:oidc_token])
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def get_access_token(server, code)
    uri = access_token_url(server, code)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def delete_cluster(server, project_slug, params)
    uri = cluster_uri(server, project_slug, cluster_name: params[:cluster_name], oidc_token: params[:oidc_token])
    response = http_client.make_delete_request(uri)

    build_response(response)
  end

  def get_account_clusters(server, account_id)
    uri = account_clusters_uri(server, account_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def get_account_controller_settings(server, account_id)
    uri = account_controller_settings_uri(server, account_id)
    response = http_client.make_get_request(uri)

    build_response(response)
  end

  def create_account_controller_settings(server, account_id, params = {})
    uri = account_controller_settings_uri(server, account_id)
    response = http_client.make_post_request(uri, params)

    build_response(response)
  end

  def update_account_controller_settings(server, account_id, id, params = {})
    uri = account_controller_setting_uri(server, account_id, id)
    response = http_client.make_put_request(uri, params)

    build_response(response)
  end

  def delete_account_controller_settings(server, account_id, id)
    uri = account_controller_setting_uri(server, account_id, id)
    response = http_client.make_delete_request(uri)

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

      @http_client = Uffizzi::HttpClient.new(params)
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
