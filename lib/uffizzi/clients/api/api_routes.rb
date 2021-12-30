# frozen_string_literal: true

module ApiRoutes
  def session_uri(hostname)
    "#{hostname}/api/cli/v1/session"
  end

  def projects_uri(hostname)
    "#{hostname}/api/cli/v1/projects"
  end

  def compose_files_uri(hostname)
    "#{hostname}/api/cli/v1/compose_files"
  end

  def deployments_uri(hostname, project_id)
    "#{hostname}/api/cli/v1/projects/#{project_id}/deployments"
  end

  def deploy_containers_uri(hostname, project_id, deployment_id)
    "#{hostname}/api/cli/v1/projects/#{project_id}/deployments/#{deployment_id}/deploy_containers"
  end
end
