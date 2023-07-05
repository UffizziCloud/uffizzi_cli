# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'bundler/setup'
require 'uffizzi/version'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: [:test, :rubocop]

desc 'Generate roff output files from ronn format'
task :generate_docs do
  sh 'ronn --roff man/*.ronn'
end

PACKAGE_NAME = 'uffizzi'
VERSION = Uffizzi::VERSION
LINUX_TRAVELING_RUBY_VERSION = '20230605-2.6.10'
MACOS_TRAVELING_RUBY_VERSION = '20230605-3.0.6'

desc 'Package your app'
task package: ['package:linux:x86_64', 'package:osx:arm64', 'package:osx:x86_64']

# rubocop:disable Naming/VariableNumber
namespace :package do
  namespace :linux do
    desc 'Package your app for Linux x86_64'
    task x86_64: [:bundle_install, "packaging/traveling-ruby-#{LINUX_TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package('linux-x86_64', LINUX_TRAVELING_RUBY_VERSION)
    end
  end

  desc 'Package your app for OS X'
  namespace :osx do
    task arm64: [:bundle_install, "packaging/traveling-ruby-#{MACOS_TRAVELING_RUBY_VERSION}-osx-arm64.tar.gz"] do
      create_package('osx-arm64', MACOS_TRAVELING_RUBY_VERSION)
    end

    task x86_64: [:bundle_install, "packaging/traveling-ruby-#{MACOS_TRAVELING_RUBY_VERSION}-osx-x86_64.tar.gz"] do
      create_package('osx-x86_64', MACOS_TRAVELING_RUBY_VERSION)
    end
  end
  # rubocop:enable Naming/VariableNumber

  desc 'Install gems to local directory'
  task :bundle_install do
    sh 'rm -rf packaging/tmp'
    sh 'mkdir packaging/tmp'
    sh 'mkdir packaging/tmp/lib'
    sh 'mkdir packaging/tmp/lib/uffizzi'
    sh 'cp lib/uffizzi/version.rb packaging/tmp/lib/uffizzi/version.rb'
    sh 'cp Gemfile uffizzi.gemspec Gemfile.lock packaging/tmp/'
    Bundler.with_clean_env do
      sh 'cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=0 bundle install --path ../vendor --without development'
    end
    sh 'rm -rf packaging/tmp'
    sh 'rm -f packaging/vendor/*/*/cache/*'
  end
end

file "packaging/traveling-ruby-#{LINUX_TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime('linux-x86_64', LINUX_TRAVELING_RUBY_VERSION)
end

file "packaging/traveling-ruby-#{MACOS_TRAVELING_RUBY_VERSION}-osx-x86_64.tar.gz" do
  download_runtime('osx-x86_64', MACOS_TRAVELING_RUBY_VERSION)
end

file "packaging/traveling-ruby-#{MACOS_TRAVELING_RUBY_VERSION}-osx-arm64.tar.gz" do
  download_runtime('osx-arm64', MACOS_TRAVELING_RUBY_VERSION)
end

def create_package(target, version)
  package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh("rm -rf #{package_dir}")
  sh("mkdir #{package_dir}")
  sh("mkdir -p #{package_dir}/lib/app")
  sh("mkdir -p #{package_dir}/lib/app/config")
  sh("mkdir -p #{package_dir}/lib/app/lib")
  sh("mkdir -p #{package_dir}/lib/app/lib/uffizzi")

  sh("cp packaging/uffizzi #{package_dir}/lib/app/uffizzi")
  sh("cp -R lib/uffizzi #{package_dir}/lib/app/lib")
  sh("cp lib/uffizzi.rb #{package_dir}/lib/app/lib/uffizzi.rb")
  sh("cp config/uffizzi.rb #{package_dir}/lib/app/config/uffizzi.rb")
  sh("mkdir #{package_dir}/lib/ruby")
  sh("tar -xzf packaging/traveling-ruby-#{version}-#{target}.tar.gz -C #{package_dir}/lib/ruby")
  sh("cp packaging/wrapper.sh #{package_dir}/uffizzi")
  sh("cp -pR packaging/vendor #{package_dir}/lib/")
  sh("cp uffizzi.gemspec Gemfile Gemfile.lock #{package_dir}/lib/vendor/")
  sh("mkdir #{package_dir}/lib/vendor/lib")
  sh("mkdir #{package_dir}/lib/vendor/lib/uffizzi")
  sh("cp lib/uffizzi/version.rb #{package_dir}/lib/vendor/lib/uffizzi/version.rb")
  sh("mkdir #{package_dir}/lib/vendor/.bundle")
  sh("cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config")
  if !ENV['DIR_ONLY']
    sh("tar -czf #{package_dir}.tar.gz #{package_dir}")
    sh("rm -rf #{package_dir}")
  end
  sh('rm -rf packaging/vendor')
end

def download_runtime(target, version)
  sh("cd packaging && curl -L -O --fail https://github.com/YOU54F/traveling-ruby/releases/download/rel-20230605/traveling-ruby-#{version}-#{target}.tar.gz")
end
