# frozen_string_literal: true

class GithubService
  class << self
    GITHUB_OUTPUT = 'GITHUB_OUTPUT'.freeze

    def write_to_github_env_if_needed(data)
      return unless ENV['GITHUB_ACTIONS']
      return '' unless data.is_a?(Hash)

      github_output = ENV.fetch(GITHUB_OUTPUT) { raise "#{GITHUB_OUTPUT} is not defined" }

      File.open(github_output, 'a') do |f|
        data.each { |(key, value)| f.puts("#{key}=#{value}") }
      end
    end
  end
end
