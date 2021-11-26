# frozen_string_literal: true

require 'json'

module ApiResponse
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

        cookie
    end
end
    