# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uffizzi/config_file'
require 'uffizzi/response_helper'

module Uffizzi
  class HttpClient
    class << self
      def make_get_request(request_uri, cookies_required = true)
        make_request(:get, request_uri, cookies_required)
      end

      def make_post_request(request_uri, params = {}, cookies_required = true)
        make_request(:post, request_uri, cookies_required, params)
      end

      def make_put_request(request_uri, cookies_required = true)
        make_request(:put, request_uri, cookies_required)
      end

      def make_delete_request(request_uri, cookies_required = true)
        make_request(:delete, request_uri, cookies_required)
      end

      private

      def make_request(method, request_uri, require_cookies, params = {})
        uri = URI(request_uri)
        use_ssl = request_uri.start_with?('https')

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
          request = build_request(uri, params, method, require_cookies)

          http.request(request)
        end

        if response.instance_of?(Net::HTTPUnauthorized)
          raise StandardError.new('Not authorized')
        end

        response
      end

      def build_request(uri, params, method, require_cookies)
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
        if request.instance_of?(Net::HTTP::Post)
          request.body = params.to_json
        end
        request['Cookie'] = ConfigFile.read_option(:cookie) if require_cookies
        if ConfigFile.exists? && ConfigFile.option_has_value?(:basic_auth_user) && ConfigFile.option_has_value?(:basic_auth_password)
          request.basic_auth(ConfigFile.read_option(:basic_auth_user), ConfigFile.read_option(:basic_auth_password))
        end

        request
      end
    end
  end
end
