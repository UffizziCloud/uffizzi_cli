# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'uffizzi'
require 'uffizzi/cli'
require 'test_setup_helper'
require 'webmock/minitest'
require 'factory_bot'
require 'net/http'
require 'uffizzi/config_file'
require 'io/console'
require 'byebug'

include FixtureSupport
include UffizziStubSupport

WebMock.disable_net_connect!

include FactoryBot::Syntax::Methods
FactoryBot.find_definitions
