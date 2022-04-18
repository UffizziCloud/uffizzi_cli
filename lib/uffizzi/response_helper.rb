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
        prepared_errors = prepare_errors(response[:body][:errors])
        raise Uffizzi::Error.new(prepared_errors)
      end

      def handle_invalid_compose_response(response)
        prepared_errors = prepare_errors(response[:body][:compose_file][:payload][:errors])
        raise Uffizzi::Error.new(prepared_errors)
      end

      private

      def prepare_errors(errors)
        errors.values.reduce('') do |acc, error_messages|
          if error_messages.is_a?(Array)
            error_messages.each { |error_message| acc = "#{acc}#{error_message}\n" }
          else
            acc = "#{acc}#{error_message}\n"
          end

          acc
        end
      end
    end
  end
end
