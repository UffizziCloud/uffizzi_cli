# frozen_string_literal: true

require 'cgi'

module ApiRoutes
  def accounts_uri(server)
    "#{server}/api/cli/v1/accounts"
  end

  def account_uri(server, account_name)
    "#{server}/api/cli/v1/accounts/#{account_name}"
  end

  def compose_file_uri(server, project_slug)
    "#{server}/api/cli/v1/projects/#{project_slug}/compose_file"
  end

  def project_uri(server, project_slug)
    "#{server}/api/cli/v1/projects/#{project_slug}"
  end

  def projects_uri(server)
    "#{server}/api/cli/v1/projects"
  end

  def account_projects_uri(server, account_id)
    "#{server}/api/cli/v1/accounts/#{account_id}/projects"
  end

  def create_projects_uri(server, account_id)
    "#{server}/api/cli/v1/accounts/#{account_id}/projects"
  end

  def secret_uri(server, project_slug, id)
    path_id = CGI.escape(id)
    "#{server}/api/cli/v1/projects/#{project_slug}/secrets/#{path_id}"
  end

  def secrets_uri(server, project_slug)
    "#{server}/api/cli/v1/projects/#{project_slug}/secrets"
  end

  def session_uri(server)
    "#{server}/api/cli/v1/session"
  end

  def ci_session_uri(server)
    "#{server}/api/cli/v1/ci/session"
  end

  def validate_compose_file_uri(server, project_slug)
    "#{compose_files_uri(server, project_slug)}/validate"
  end

  def deployments_uri(server, project_slug, filter = nil)
    return "#{server}/api/cli/v1/projects/#{project_slug}/deployments" if filter.nil?

    "#{server}/api/cli/v1/projects/#{project_slug}/deployments?q=#{filter.to_json}"
  end

  def deployment_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}"
  end

  def activity_items_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/activity_items"
  end

  def deploy_containers_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/deploy_containers"
  end

  def events_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/events"
  end

  def check_credential_uri(server, account_id, type)
    "#{server}/api/cli/v1/accounts/#{account_id}/credentials/#{type}/check_credential"
  end

  def credentials_uri(server, account_id)
    "#{server}/api/cli/v1/accounts/#{account_id}/credentials"
  end

  def preview_services_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/containers"
  end

  def credential_uri(server, account_id, credential_type)
    "#{server}/api/cli/v1/accounts/#{account_id}/credentials/#{credential_type}"
  end

  def preview_service_logs_uri(server, project_slug, deployment_id, container_name)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/containers/#{container_name}/logs"
  end

  def k8s_container_description_uri(server, project_slug, deployment_id, container_name)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/containers/#{container_name}/k8s_container_description"
  end

  def clusters_uri(server, project_slug, filter = nil)
    return "#{server}/api/cli/v1/projects/#{project_slug}/clusters" if filter.nil?

    "#{server}/api/cli/v1/projects/#{project_slug}/clusters?q=#{filter.to_json}"
  end

  def cluster_uri(server, project_slug, cluster_name)
    "#{server}/api/cli/v1/projects/#{project_slug}/clusters/#{cluster_name}"
  end

  def access_token_url(server, code)
    "#{server}/api/cli/v1/access_tokens/#{code}"
  end

  def access_tokens_url(server)
    "#{server}/api/cli/v1/access_tokens"
  end

  def browser_sign_in_url(server, session_id)
    "#{server}/sign_in?session_id=#{session_id}"
  end
end
