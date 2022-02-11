# frozen_string_literal: true

module Uffizzi
  module ResponseHelper
    class << self
      def created?(response)
        response[:code] == Net::HTTPCreated
      end

      def unprocessable_entity?(response)
        response[:code] == Net::HTTPUnprocessableEntity
      end

      def not_found?(response)
        response[:code] == Net::HTTPNotFound
      end

      def forbidden?(response)
        response[:code] == Net::HTTPForbidden
      end

      def no_content?(response)
        response[:code] == Net::HTTPNoContent
      end

      def ok?(response)
        response[:code] == Net::HTTPOK
      end
    end
  end
end
