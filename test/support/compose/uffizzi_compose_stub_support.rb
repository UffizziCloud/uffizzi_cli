# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'

module UffizziComposeStubSupport
  include ApiRoutes

  def stub_uffizzi_create_compose(base_url, status, body, headers, project_slug)
    url = compose_file_uri(base_url, project_slug)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_unset_compose(base_url, status, body, headers, project_slug)
    url = compose_file_uri(base_url, project_slug)

    stub_request(:delete, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_describe_compose(base_url, status, body, headers, project_slug)
    url = compose_file_uri(base_url, project_slug)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_validate_compose(base_url, status, body, headers, project_slug)
    url = validate_compose_file_uri(base_url, project_slug)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end
end
