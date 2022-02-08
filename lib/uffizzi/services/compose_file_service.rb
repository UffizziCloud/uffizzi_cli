# frozen_string_literal: true

require 'psych'
require 'pathname'
require 'base64'

class ComposeFileService
  class << self
    def parse(compose_content, compose_file_path)
      compose_data = load_compose_data(compose_content)

      env_files = prepare_services_env_files(compose_data['services']).flatten.uniq
      config_files = fetch_configs(compose_data['configs'])
      prepare_dependencies(env_files, config_files, compose_file_path)
    end

    private

    def prepare_dependencies(env_files, config_files, compose_file_path)
      prepared_env_files = prepare_env_files_data(env_files, compose_file_path)
      prepared_config_files = prepare_config_files_data(config_files, compose_file_path)

      prepared_env_files + prepared_config_files
    end

    def prepare_env_files_data(env_files, compose_file_path)
      env_files.map do |env_file|
        env_file_data = Psych.load(File.read("#{compose_file_path}/#{env_file}"))
        {
          path: env_file,
          source: env_file,
          content: Base64.encode64(env_file_data),
        }
      end
    end

    def prepare_config_files_data(config_files, compose_file_path)
      config_files.map do |config_file|
        config_file_data = Psych.load(File.read("#{compose_file_path}/#{config_file}"))
        {
          path: config_file,
          source: config_file,
          content: Base64.encode64(config_file_data),
        }
      end
    end

    def fetch_configs(configs_data)
      return [] if configs_data.nil?

      Uffizzi.ui.say("Unsupported type of #{:configs} option") unless configs_data.is_a?(Hash)

      configs = []
      configs_data.each_pair do |config_name, config_data|
        Uffizzi.ui.say("#{config_name} has an empty file") if config_data['file'].empty? || config_data['file'].nil?

        configs << prepare_file_path(config_data['file'])
      end

      configs
    end

    def prepare_file_path(file_path)
      Uffizzi.ui.say('env_file contains an empty value') if file_path.nil? || file_path.empty?

      pathname = Pathname.new(file_path)

      pathname.cleanpath.to_s.strip.delete_prefix('/')
    end

    def parse_env_file(env_file)
      case env_file
      when String
        [prepare_file_path(env_file)]
      when Array
        env_file.map { |env_file_path| prepare_file_path(env_file_path) }
      else
        Uffizzi.ui.say("Unsupported type of #{:env_file} option")
      end
    end

    def prepare_services_env_files(services)
      services.keys.map do |service|
        service_env_files = prepare_service_env_files(services.fetch(service))

        service_env_files
      end
    end

    def prepare_service_env_files(service_data)
      env_files_data = []
      service_data.each_pair do |key, value|
        key_sym = key.to_sym
        if key_sym == :env_file
          env_files_data << parse_env_file(value)
        end
      end

      env_files_data
    end

    def load_compose_data(compose_content)
      begin
        compose_data = Psych.safe_load(compose_content)
      rescue Psych::SyntaxError
        Uffizzi.ui.say('Invalid compose file')
      end

      Uffizzi.ui.say('Unsupported compose file') if compose_data.nil?

      compose_data
    end
  end
end
