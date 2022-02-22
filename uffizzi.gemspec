# frozen_string_literal: true

require_relative 'lib/uffizzi/version'

Gem::Specification.new do |spec|
  spec.name = 'uffizzi-cli'
  spec.version = Uffizzi::VERSION
  spec.authors = ['Josh Thurman', 'Grayson Adkins']
  spec.email = ['info@uffizzi.com']

  spec.summary = 'uffizzi-cli'
  spec.description = 'uffizzi-cli'
  spec.homepage = 'https://uffizzi.com'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/UffizziCloud/uffizzi_cli'
  spec.metadata['changelog_uri'] = 'https://github.com/UffizziCloud/uffizzi_cli/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-power_assert'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-inline'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'io-console'
  spec.add_dependency 'thor'
end
