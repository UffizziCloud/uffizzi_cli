# frozen_string_literal: true

require 'thor'
require 'io/console'

module Uffizzi
  class CLI < Thor
    desc 'version', 'show version'
    def version
      puts Uffizzi::VERSION
    end

    desc 'login', 'login'
    method_option :user, :required => true, :aliases => '-u'
    method_option :hostname, :required => true, :aliases => '-h'
    def login
      password = IO::console.getpass "Enter Password: "
      {
        user: options[:user],
        password: password.strip,
        hostname: options[:hostname]
      }
    end
  end
end
