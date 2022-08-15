# frozen_string_literal: true

require 'cgi'

module ApiRoutes
  def compose_file_uri(server, project_slug)
    "#{server}/api/cli/v1/projects/#{project_slug}/compose_file"
  end

  def project_uri(server, project_slug)
    "#{server}/api/cli/v1/projects/#{project_slug}"
  end

  def projects_uri(server)
    "#{server}/api/cli/v1/projects"
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

  def check_credential_uri(server, type)
    "#{server}/api/cli/v1/account/credentials/#{type}/check_credential"
  end

  def credentials_uri(server)
    "#{server}/api/cli/v1/account/credentials"
  end

  def preview_services_uri(server, project_slug, deployment_id)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/containers"
  end

  def credential_uri(server, credential_type)
    "#{server}/api/cli/v1/account/credentials/#{credential_type}"
  end

  def preview_service_logs_uri(server, project_slug, deployment_id, container_name)
    "#{server}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/containers/#{container_name}/logs"
  end
end
