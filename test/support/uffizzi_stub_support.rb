# frozen_string_literal: true

require 'uffizzi'

module UffizziStubSupport
  include ApiRoutes

  def stub_uffizzi_login(base_url, status, body, headers)
    url = session_uri(base_url)

    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_projects(base_url, status, body, headers)
    url = projects_uri(base_url)

    stub_request(:get, url).to_return(status: status, body: body.to_json, headers: headers)
  end
end
