# frozen_string_literal: true

require_relative 'api_routes'
require_relative 'http_client'

module ApiClient
  include ApiRoutes
  def create_session(hostname, params = {})
    uri = session_uri(hostname)
    response = Uffizzi::HttpClient.make_request(uri, :post, false, params)

    response
  end
end