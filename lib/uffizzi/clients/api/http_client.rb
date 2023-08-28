# frozen_string_literal: true

require 'net/http'
require 'json'

module Uffizzi
  class HttpClient
    attr_accessor :auth_cookie, :basic_auth_user, :basic_auth_password

    def initialize(params)
      @auth_cookie = params[:cookie]
      @basic_auth_user = params[:basic_auth_user]
      @basic_auth_password = params[:basic_auth_password]
    end

    def make_get_request(request_uri)
      make_request(:get, request_uri)
    end

    def make_post_request(request_uri, params = {})
      make_request(:post, request_uri, params)
    end

    def make_put_request(request_uri, params = {})
      make_request(:put, request_uri, params)
    end

    def make_delete_request(request_uri)
      make_request(:delete, request_uri)
    end

    private

    def make_request(method, request_uri, params = {})
      uri = URI(request_uri)
      use_ssl = request_uri.start_with?('https')

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
        request = build_request(uri, params, method)

        http.request(request)
      end

      if response.is_a?(Net::HTTPUnauthorized)
        Uffizzi::Token.delete if Uffizzi::Token.exists?
        raise Uffizzi::Error.new('Not authorized')
      end

      response
    end

    def build_request(uri, params, method)
      access_token = Uffizzi::Token.read
      headers = get_headers(access_token)
      request = case method
                when :get
                  Net::HTTP::Get.new(uri.request_uri, headers)
                when :post
                  Net::HTTP::Post.new(uri.request_uri, headers)
                when :delete
                  Net::HTTP::Delete.new(uri.request_uri, headers)
                when :put
                  Net::HTTP::Put.new(uri.request_uri, headers)
      end
      if request.instance_of?(Net::HTTP::Post) || request.instance_of?(Net::HTTP::Put)
        request.body = params.to_json
      end
      request['Cookie'] = @auth_cookie
      request.basic_auth(@basic_auth_user, @basic_auth_password) unless access_token

      request
    end

    def get_headers(access_token)
      content_type_headers = { 'Content-Type' => 'application/json' }
      auth_headers = access_token ? { 'Authorization' => "Bearer #{access_token}" } : {}
      cli_version = { 'x-uffizzi-cli-version' => Uffizzi::VERSION }

      content_type_headers.merge(auth_headers).merge(cli_version)
    end
  end
end
