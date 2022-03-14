# frozen_string_literal: true

require 'uffizzi/clients/api/api_routes'
require_relative '../../config/uffizzi'

module UffizziStubSupport
  include ApiRoutes

  def stub_uffizzi_login_success(body, headers)
    url = session_uri(Uffizzi.configuration.hostname)

    stub_request(:post, url).to_return(status: 201, body: body.to_json, headers: headers)
  end

  def stub_uffizzi_login_failed(body)
    url = session_uri(Uffizzi.configuration.hostname)

    stub_request(:post, url).to_return(status: 422, body: body.to_json)
  end

  def stub_uffizzi_logout(headers)
    url = session_uri(Uffizzi.configuration.hostname)

    stub_request(:delete, url).to_return(status: 204, body: '', headers: headers)
  end

  def stub_uffizzi_projects_success(body)
    url = projects_uri(Uffizzi.configuration.hostname)

    stub_request(:get, url).to_return(status: 200, body: body.to_json)
  end

  def stub_uffizzi_projects_failed(body)
    url = projects_uri(Uffizzi.configuration.hostname)

    stub_request(:get, url).to_return(status: 401, body: body.to_json)
  end
end
