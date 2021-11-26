# frozen_string_literal: true

require_relative 'uffizzi/version'
require_relative 'uffizzi/clients/api/api_client'
require_relative 'uffizzi/clients/api/api_response'
require_relative 'uffizzi/clients/api/api_routes'
require_relative 'uffizzi/config'

module Uffizzi
  class Error < StandardError; end
end
