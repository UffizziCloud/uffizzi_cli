# frozen_string_literal: true

require 'psych'
require 'pathname'
require 'base64'
require 'byebug'

class EnvVariablesService
  class << self
    def substitute_env_variables(compose_file_data)
      compose_file_data.gsub(/\$\{?([?:\-_A-Za-z0-9]+)\}?/) do |variable|
        variable_content = variable.match(/[?:\-_A-Za-z0-9]+/).to_s
        fetch_variable_value(variable_content)
      end
    end

    private

    def fetch_variable_value(variable_content)
      variable_name = variable_content.match(/^[_A-Za-z0-9]+/).to_s
      variable_value = ENV[variable_name]
      return variable_value unless variable_value.nil?
      return fetch_variable_default_value(variable_content) if variable_has_default_value?(variable_content)

      error_message = if variable_has_error_message?(variable_content)
        fetch_env_error_message(variable_content)
      else
        "Environment variable #{variable_name} doesn't exist"
      end
      raise StandardError.new(error_message)
    end

    def variable_has_default_value?(variable_content)
      variable_content.include?('-')
    end

    def fetch_variable_default_value(variable_content)
      variable_content.split('-', 2).last
    end

    def variable_has_error_message?(variable_content)
      variable_content.include?('?')
    end

    def fetch_env_error_message(variable_content)
      variable_content.split('?', 2).last
    end
  end
end
