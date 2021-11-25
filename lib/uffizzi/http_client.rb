# frozen_string_literal: true

require 'net/http'
require 'json'

module Uffizzi
  class HttpClient
    class << self
      def make_request(params, hostname)
        uri = URI(hostname)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
          request.body = { user: { email: params[:user], password: params[:password] } }.to_json
          http.request(request)
        end

        response
      end

      def get_body_from_response(response)
        body = JSON.parse(response.body)

        body
      end

      def get_cookie_from_response(response)
        cookie = response.to_hash['set-cookie'].first.split(';').first,

        cookie
      end
    end
  end
end
