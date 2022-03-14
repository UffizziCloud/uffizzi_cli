# frozen_string_literal: true

module ApiRoutes
  def session_uri(hostname)
    "#{hostname}/api/cli/v1/session"
  end

  def projects_uri(hostname)
    "#{hostname}/api/cli/v1/projects"
  end

  def compose_file_uri(hostname, project_slug)
    "#{hostname}/api/cli/v1/projects/#{project_slug}/compose_file"
  end
end
