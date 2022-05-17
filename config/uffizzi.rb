# frozen_string_literal: true

require 'ostruct'

module Uffizzi
  def self.configuration
    @configuration ||= OpenStruct.new
  end

  def self.configure
    yield(configuration)
  end

  configure do |config|
    config.server = 'http://web:7000'
    config.credential_types = {
      dockerhub: 'UffizziCore::Credential::DockerHub',
      azure: 'UffizziCore::Credential::Azure',
      google: 'UffizziCore::Credential::Google',
      amazon: 'UffizziCore::Credential::Amazon',
      github_registry: 'UffizziCore::Credential::GithubContainerRegistry',
    }
    config.default_server = 'app.uffizzi.com'
  end
end
