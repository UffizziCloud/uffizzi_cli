# frozen_string_literal: true

require 'psych'
require 'pathname'
require 'base64'
require 'minitar'
require 'zlib'
require 'uffizzi/services/project_service'
require 'uffizzi/services/volume_parser_service'

require 'byebug'

class ComposeFileService
  MAX_HOST_VOLUME_GZIP_FILE_SIZE = 1024 * 900
  DEPENDENCY_CONFIG_USE_KIND = :config_map.freeze
  DEPENDENCY_VOLUME_USE_KIND = :volume.freeze

  class << self
    def parse(compose_content, compose_file_dir)
      compose_data = parse_compose_content_to_object(compose_content)

      services = compose_data['services']
      env_files_paths = prepare_env_files_paths(services).flatten.uniq
      config_files_paths = prepare_config_files_paths(compose_data['configs'])
      host_volumes_paths = prepare_host_volumes_paths(services)
      prepare_dependencies(compose_file_dir, env_files_paths, config_files_paths, host_volumes_paths)
    end

    private

    def prepare_dependencies(compose_file_dir, env_files_paths, config_files_paths, host_volumes_paths)
      config_files_attrs = prepare_dependency_configs_files(env_files_paths + config_files_paths, compose_file_dir)
      host_volumes_attrs = prepare_dependency_host_volumes_files(host_volumes_paths, compose_file_dir)

      config_files_attrs + host_volumes_attrs
    end

    def prepare_dependency_configs_files(dependency_file_paths, compose_file_dir)
      dependency_file_paths.map do |dependency_file_path|
        dependency_file_content = Psych.load(File.read("#{compose_file_dir}/#{dependency_file_path}"))

        {
          path: dependency_file_path,
          source: dependency_file_path,
          content: Base64.encode64(dependency_file_content),
          use_kind: DEPENDENCY_CONFIG_USE_KIND,
        }
      end
    rescue Errno::ENOENT => e
      dependency_path = e.message.split('- ').last
      raise Uffizzi::Error.new("The config file #{dependency_path} does not exist")
    end

    def prepare_dependency_host_volumes_files(dependency_file_paths, compose_file_dir)
      dependency_file_paths.map do |dependency_file_path|
        base_dependency_path = if Pathname.new(dependency_file_path).absolute?
                                 dependency_file_path
                               elsif (/^\.\//.match?(dependency_file_path)) # start with ./
                                 path = "#{compose_file_dir}/#{Pathname.new(dependency_file_path).cleanpath.to_s}"
                               elsif (/^\.\.\//.match?(dependency_file_path)) # start with ../
                                 path = "#{compose_file_dir}/#{dependency_file_path}"
                               else
                                 Uffizzi.ui.say("Unsupported path #{dependency_file_path}")
                               end

        absolute_dependency_path = Pathname.new(base_dependency_path).realpath.to_s
        dependency_file_content = prepare_host_volume_file_content(absolute_dependency_path)

        {
          path: absolute_dependency_path,
          source: dependency_file_path,
          content: dependency_file_content,
          use_kind: DEPENDENCY_VOLUME_USE_KIND,
          is_file: Pathname.new(absolute_dependency_path).file?,
        }
      end
    rescue Errno::ENOENT => e
      dependency_path = e.message.split('- ').last
      raise Uffizzi::Error.new("The file #{dependency_path} does not exist")
    end

    def prepare_host_volume_file_content(path)
      tmp_tar_name = Base64.encode64(path)[0..20]
      tmp_tar_path = "/tmp/#{tmp_tar_name}.tar.gz"

      Minitar.pack(path, Zlib::GzipWriter.new(File.open(tmp_tar_path, 'wb')))
      Uffizzi.ui.say("Unsupported path #{path}") if Pathname.new(tmp_tar_path).size > MAX_HOST_VOLUME_GZIP_FILE_SIZE

      Base64.encode64(File.binread(tmp_tar_path))
    end

    def prepare_config_files_paths(configs_data)
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
      pathname = Pathname.new(file_path)

      pathname.cleanpath.to_s.strip.delete_prefix('/')
    end

    def parse_env_file(env_file)
      case env_file
      when String
        Uffizzi.ui.say('env_file contains an empty value') if env_file.nil? || env_file.empty?
        [prepare_file_path(env_file)]
      when Array
        Uffizzi.ui.say('env_file contains an empty value') if env_file.any? { |file| file.nil? || file.empty? }
        env_file.map { |env_file_path| prepare_file_path(env_file_path) }
      else
        Uffizzi.ui.say("Unsupported type of #{:env_file} option")
      end
    end

    def prepare_env_files_paths(services)
      return [] if services.nil?

      services.map do |_, service_data|
        service_data.map do |key, value|
          parse_env_file(value) if key.to_sym == :env_file
        end
      end.flatten.compact.uniq
    end

    def parse_compose_content_to_object(compose_content)
      begin
        compose_data = Psych.safe_load(compose_content, aliases: true)
      rescue Psych::SyntaxError
        Uffizzi.ui.say('Invalid compose file')
      end

      Uffizzi.ui.say('Unsupported compose file') if compose_data.nil?

      compose_data
    end

    def prepare_host_volumes_paths(services)
      return [] if services.nil?

      services.map do |_, service_data|
        service_data.map do |key, value|
          VolumeParserService.parse(value) if key.to_sym == :volumes
        end
      end.flatten.compact.uniq
    end
  end
end
