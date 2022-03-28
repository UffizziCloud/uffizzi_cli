# frozen_string_literal: true

require 'cgi'

module ApiRoutes
  def compose_file_uri(hostname, project_slug)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/compose_file"
  end

  def projects_uri(hostname)
    "#{hostname}/api/cli/v1/projects"
  end

  def secret_uri(hostname, project_slug, id)
    path_id = CGI.escape(id)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/secrets/#{path_id}"
  end

  def secrets_uri(hostname, project_slug)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/secrets"
  end

  def session_uri(hostname)
    "#{hostname}/api/cli/v1/session"
  end

  def validate_compose_file_uri(hostname, project_slug)
    "#{compose_files_uri(hostname, project_slug)}/validate"
  end

  def deployments_uri(hostname, project_slug)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/deployments"
  end

  def deployment_uri(hostname, project_slug, deployment_id)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}"
  end

  def activity_items_uri(hostname, project_slug, deployment_id)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/activity_items"
  end

  def deploy_containers_uri(hostname, project_slug, deployment_id)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/deploy_containers"
  end

  def events_uri(hostname, project_slug, deployment_id)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/deployments/#{deployment_id}/events"
  end

  def credentials_uri(hostname)
    "#{hostname}/api/cli/v1/account/credentials"
  end
end
