# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uffizzi/config'

module Uffizzi
  class HttpClient
    class << self
      def make_request(request_uri, method, require_cookies, params = {})
        uri = URI(request_uri)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = build_request(uri, params, method, require_cookies)
          http.request(request)
        end
      end

      private

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

        request['set-cookie'] = Config.read_option(:cookie) if require_cookies
        request.body = params.to_json
        if (Config.option_exists?(:basic_auth_user) && Config.option_exists?(:basic_auth_password))
          request.basic_auth(Config.read_option(:basic_auth_user), Config.read_option(:basic_auth_password))
        end
        request
      end
    end
  end
end
