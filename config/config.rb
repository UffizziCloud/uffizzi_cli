require 'ostruct'
module Uffizzi
  def self.configuration
    @configuration ||= OpenStruct.new
  end
  
  def self.configure
    yield(configuration)
  end

  configure do |config|
    config.hostname = "http://web:7000"
  end
end
