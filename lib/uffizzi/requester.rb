# frozen_string_literal: true

require 'net/http'
require 'json'

module Uffizzi
  class Requester
  
    def self.request(params, hostname)
      uri = URI(hostname)
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = { user: { email: params[:user], password: params[:password] } }.to_json
        http.request(req)
      end

      {
        code: res.code,
        cookie: res.to_hash['set-cookie'],
        body: JSON.parse(res.body.gsub('=>', ':').gsub(':nil,', ':null,'))
      }
    end
  end
end
