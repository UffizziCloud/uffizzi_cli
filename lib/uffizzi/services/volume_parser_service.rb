# frozen_string_literal: true

class VolumeParserService
  class << self
    def parse(volumes)
      return [] if volumes.empty?

      Uffizzi.ui.say("Volumes '#{volumes}' should be an array") if volumes.is_a?(String)

      volumes.map { |volume| parse_volume(volume) }
    end

    private

    def parse_volume(volume)
      case volume
      when String
        process_short_syntax(volume)
      when Hash
        process_long_syntax(volume)
      else
        Uffizzi.ui.say("Unsupported type of '#{volumes}' option")
      end
    end

    def process_short_syntax(volume_data)
      path_part1, path_part2 = volume_data.split(':').map(&:strip)

      path_part1 if host_volume?(path_part1, path_part2)
    end

    def process_long_syntax(volume_data)
      source_path = volume_data['source'].to_s.strip
      target_path = volume_data['target'].to_s.strip

      source_path if host_volume?(source_path, target_path)
    end

    def host_volume?(source_path, target_path)
      path?(source_path) && path?(target_path)
    end

    def path?(path)
      /^(\/|\.\/|\.\.\/)/.match?(path) # volume path should start with / or ./ or ../
    end
  end
end
