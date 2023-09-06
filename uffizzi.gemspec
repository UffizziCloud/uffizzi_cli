# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'uffizzi/version'

Gem::Specification.new do |spec|
  spec.name = 'uffizzi-cli'
  spec.version = Uffizzi::VERSION
  spec.authors = ['Josh Thurman', 'Grayson Adkins']
  spec.email = ['info@uffizzi.com']

  spec.summary = 'uffizzi-cli'
  spec.description = 'uffizzi-cli'
  spec.homepage = 'https://uffizzi.com'
  spec.license = 'Apache-2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/UffizziCloud/uffizzi_cli'
  spec.metadata['changelog_uri'] = 'https://github.com/UffizziCloud/uffizzi_cli/blob/master/CHANGELOG.md'

  spec.bindir = 'exe'
  spec.executables = ['uffizzi']

  spec.files = Dir['{lib}/**/*', '{config}/**/*', '{man}/**/*'] + ['README.md', 'LICENSE']

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'
end
