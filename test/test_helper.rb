# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'factory_bot'
require 'faker'
require 'net/http'
require 'io/console'
require 'byebug'
require 'minitest/autorun'
require 'webmock/minitest'
require 'mocha/minitest'

require_relative '../config/uffizzi'
require 'uffizzi'
require 'uffizzi/cli'
require 'uffizzi/config_file'
require 'uffizzi/shell'

include AuthSupport
include FixtureSupport
include UffizziStubSupport
include UffizziComposeStubSupport
include UffizziPreviewStubSupport

WebMock.disable_net_connect!

include FactoryBot::Syntax::Methods
FactoryBot.find_definitions

class Minitest::Test
  TEST_CONFIG_PATH = 'tmp/config_default.json'

  def before_setup
    super

    @mock_shell = MockShell.new
    Uffizzi::UI::Shell.stubs(:new).returns(@mock_shell)
    Uffizzi::ConfigFile.stubs(:config_path).returns(TEST_CONFIG_PATH)
  end

  def before_teardown
    super

    Uffizzi::ConfigFile.delete
  end
end
