# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'uffizzi'
require 'minitest/autorun'
require 'webmock/minitest'

include FixtureSupport
include UffizziStubSupport

WebMock.disable_net_connect!
