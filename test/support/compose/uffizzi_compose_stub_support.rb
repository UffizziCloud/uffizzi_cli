# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziComposeStubSupport
  include ApiRoutes

  def stub_uffizzi_create_compose_success(body, project_slug)
    url = compose_file_uri(Uffizzi.configuration.hostname, project_slug)

    stub_request(:post, url).to_return(status: 201, body: body.to_json)
  end

  def stub_uffizzi_create_compose_failed(body, project_slug)
    url = compose_file_uri(Uffizzi.configuration.hostname, project_slug)

    stub_request(:post, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_unset_compose_success(body, project_slug)
    url = compose_file_uri(Uffizzi.configuration.hostname, project_slug)

    stub_request(:delete, url).to_return(status: 204, body: body.to_json)
  end

  def stub_uffizzi_unset_compose_failed(body, project_slug)
    url = compose_file_uri(Uffizzi.configuration.hostname, project_slug)

    stub_request(:delete, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_describe_compose(body, project_slug)
    url = compose_file_uri(Uffizzi.configuration.hostname, project_slug)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end
end
