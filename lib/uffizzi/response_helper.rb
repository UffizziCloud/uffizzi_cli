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

      def handle_failed_response(response, addtional_errors = [])
        errors = get_response_errors(response)
        common_msg = errors_to_string(errors)
        addtional_msg = errors_to_string(addtional_errors)
        message = [common_msg, addtional_msg]
          .reject { |m| m == '' }
          .join("\n")
          .concat("\n")

        raise Uffizzi::Error.new("Server Error:\n#{message}")
      end

      def handle_invalid_compose_response(response)
        message = errors_to_string(response[:body][:compose_file][:payload][:errors])
        raise Uffizzi::Error.new(message)
      end

      def get_response_errors(response)
        return response if response.is_a?(Array)
        return [response.to_s] unless response.is_a?(Hash)

        body = response.fetch(:body, response.to_s)
        return [body.to_s] unless body.is_a?(Hash)

        errors = body.fetch(:errors, body.to_s)
        return [errors.to_s] unless [Hash, Array].include?(errors.class)

        errors
      end

      private

      def errors_to_string(errors)
        return errors.join("\n") if errors.is_a?(Array)
        return errors.to_s unless errors.is_a?(Hash)

        errors
          .values
          .flatten
          .map { |msg| prepare_error_message(msg.to_s) }
          .join("\n")
      end

      def prepare_error_message(error_message)
        error_message.split('::').last
      end
    end
  end
end
