# frozen_string_literal: true

require 'psych'
require 'pathname'
require 'base64'
require 'minitar'
require 'zlib'
require 'uffizzi/services/project_service'
require 'uffizzi/services/volume_parser_service'

class ComposeFileService
  MAX_HOST_VOLUME_GZIP_FILE_SIZE = 1024 * 900
  DEPENDENCY_CONFIG_USE_KIND = :config_map
  DEPENDENCY_VOLUME_USE_KIND = :volume

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
        dependency_file_content = File.read("#{compose_file_dir}/#{dependency_file_path}")

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
      base_dependency_paths = dependency_file_paths.map do |dependency_file_path|
        dependency_pathname = Pathname.new(dependency_file_path)
        next dependency_file_path if dependency_pathname.absolute?
        next "#{compose_file_dir}/#{dependency_pathname.cleanpath}" if dependency_file_path.start_with?('./')
        next "#{compose_file_dir}/#{dependency_pathname}" if dependency_file_path.start_with?('../')

        raise Uffizzi::Error.new("Unsupported path #{dependency_pathname}")
      end

      base_dependency_paths.zip(dependency_file_paths).map do |base_dependency_path, dependency_file_path|
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
      raise Uffizzi::Error.new("No such file or directory: #{dependency_path}")
    end

    def prepare_host_volume_file_content(path)
      tmp_tar_name = Base64.encode64(path)[0..20]
      tmp_tar_path = "/tmp/#{tmp_tar_name}.tar.gz"

      Minitar.pack(path, Zlib::GzipWriter.new(File.open(tmp_tar_path, 'wb')))
      gzipped_file_size = Pathname.new(tmp_tar_path).size

      if gzipped_file_size > MAX_HOST_VOLUME_GZIP_FILE_SIZE
        raise Uffizzi::Error.new("File or directory is too large:: #{path}. Gzipped tar archive size is #{gzipped_file_size}")
      end

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

      services
        .values
        .select { |s| s.has_key?('env_file') }
        .map { |s| parse_env_file(s['env_file']) }
        .flatten
        .compact
        .uniq
    end

    def parse_compose_content_to_object(compose_content)
      begin
        compose_data = Psych.safe_load(compose_content, aliases: true)
      rescue Psych::SyntaxError => e
        err = [e.problem, e.context].compact.join(' ')
        raise Uffizzi::Error.new("Syntax error: #{err} at line #{e.line} column #{e.column}")
      end

      raise Uffizzi::Error.new('Unsupported compose file') if compose_data.nil?

      compose_data
    end

    def prepare_host_volumes_paths(services)
      return [] if services.nil?

      services
        .values
        .select { |s| s.has_key?('volumes') }
        .map { |s| VolumeParserService.parse(s['volumes']) }
        .flatten
        .compact
        .uniq
    end
  end
end
