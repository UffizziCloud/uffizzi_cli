# frozen_string_literal: true

require 'net/http'
require 'json'

module Uffizzi
  class HttpClient
    attr_accessor :auth_cookie, :basic_auth_user, :basic_auth_password

    def initialize(auth_cookie, basic_auth_user, basic_auth_password)
      @auth_cookie = auth_cookie
      @basic_auth_user = basic_auth_user
      @basic_auth_password = basic_auth_password
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

      raise Uffizzi::Error.new('Not authorized') if response.is_a?(Net::HTTPUnauthorized)

      response
    end

    def build_request(uri, params, method)
      headers = { 'Content-Type' => 'application/json' }
      request = case method
                when :get
                  Net::HTTP::Get.new(uri.path, headers)
                when :post
                  Net::HTTP::Post.new(uri.path, headers)
                when :delete
                  Net::HTTP::Delete.new(uri.path, headers)
                when :put
                  Net::HTTP::Put.new(uri.path, headers)
      end
      if request.instance_of?(Net::HTTP::Post) || request.instance_of?(Net::HTTP::Put)
        request.body = params.to_json
      end
      request['Cookie'] = @auth_cookie
      request.basic_auth(@basic_auth_user, @basic_auth_password)

      request
    end
  end
end
