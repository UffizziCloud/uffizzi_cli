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

      def handle_failed_response(response)
        print_errors(response[:body][:errors])
      end

      def handle_invalid_compose_response(response)
        print_errors(response[:body][:compose_file][:payload][:errors])
      end

      private

      def print_errors(errors)
        errors.each_key do |key|
          if errors[key].is_a?(Array)
            errors[key].each { |error_message| Uffizzi.ui.say(error_message) }
          else
            Uffizzi.ui.say(errors[key])
          end
        end
      end
    end
  end
end
