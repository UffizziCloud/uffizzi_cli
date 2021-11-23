# frozen_string_literal: true

require 'thor'
require 'io/console'
require 'net/http'
require 'json'
require 'fileutils'

module Uffizzi
  SUCCESS_CODE = '201'
  CONFIG_PATH = "#{Dir.home}/uffizzi/config.json"

  class CLI < Thor
    desc 'version', 'show version'
    def version
      puts Uffizzi::VERSION
    end

    desc 'login', 'login'
    method_option :user, required: true, aliases: '-u'
    method_option :hostname, required: true, aliases: '-h'
    def login
      password = IO::console.getpass('Enter Password: ')

      uri = URI(options[:hostname])
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = { user: { email: options[:user], password: password.strip } }.to_json
        http.request(req)
      end
      if res.code == SUCCESS_CODE
        body = JSON.parse(res.body.gsub('=>', ':').gsub(':nil,', ':null,'))
        cookie = res.to_hash['set-cookie'].first.split(';').first
        account_data = {
          id: body['user']['accounts'].first['id'],
        }
        data = {
          account: account_data,
          hostname: options[:hostname],
          cookie: cookie,
        }
        file = create_file(CONFIG_PATH)
        file.write(data.to_json)
      else
        puts JSON.parse(res.body)['errors'].first.pop
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
