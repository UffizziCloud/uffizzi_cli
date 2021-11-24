# frozen_string_literal: true

require 'io/console'
require 'json'
require 'fileutils'
require 'uffizzi'

module Uffizzi
  class CLI::Login
  
    SUCCESS_CODE = '201'
    CONFIG_PATH = "#{Dir.home}/uffizzi/config.json"

    def initialize(options)
      @options = options
    end

    def run
      password = IO::console.getpass('Enter Password: ')

      params = {
        user: @options[:user],
        password: password.strip
      }
      res = Requester.request(params, @options[:hostname])
      if res[:code] == SUCCESS_CODE
        account_data = {
          id: res[:body]['user']['accounts'].first['id'],
        }
        data = {
          account: account_data,
          hostname: @options[:hostname],
          cookie: res[:cookie].first.split(';').first,
        }
        file = create_file(CONFIG_PATH)
        file.write(data.to_json)
      else
        puts res[:body]["errors"].first.pop
      end
    end

    private

    def create_file(path)
      dir = File.dirname(path)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      File.new(path, 'w')
    end
  end
end
