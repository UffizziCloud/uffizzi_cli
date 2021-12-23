# frozen_string_literal: true

require_relative 'api_routes'
require_relative 'http_client'

module ApiClient
  include ApiRoutes
  def create_session(hostname, params = {})
    uri = session_uri(hostname)
    response = Uffizzi::HttpClient.make_request(uri, :post, false, params)

    build_response(response)
  end

  def fetch_projects(hostname)
    uri = projects_uri(hostname)
    response = Uffizzi::HttpClient.make_request(uri, :get, true)

    build_response(response)
  end

  private

  def build_response(response)
    {
      body: response_body(response),
      headers: response_cookie(response),
      code: response.class
    }
  end

  def response_body(response)
    return nil if response.body.nil?
    body = JSON.parse(response.body, symbolize_names: true)

    body
  end

  def response_cookie(response)
    cookies = response.to_hash['set-cookie']
    return nil if cookies.nil?
    cookie_content = cookies.first
    cookie = cookie_content.split(';').first
    Uffizzi::ConfigFile.rewrite_cookie(cookie) if Uffizzi::ConfigFile.exists?

    cookie
  end
end