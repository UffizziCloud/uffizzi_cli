# frozen_string_literal: true

module ApiRoutes
  def compose_file_uri(hostname, project_slug)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/compose_file"
  end

  def projects_uri(hostname)
    "#{hostname}/api/cli/v1/projects"
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
end
