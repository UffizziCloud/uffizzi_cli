# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'factory_bot'
require 'faker'
require 'net/http'
require 'io/console'
require 'minitest/autorun'
require 'webmock/minitest'
require 'mocha/minitest'
require 'deepsort'
require 'fakefs/safe'

require_relative '../config/uffizzi'
require 'uffizzi'
require 'uffizzi/cli'
require 'uffizzi/config_file'
require 'uffizzi/shell'
require 'uffizzi/error'
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
  TEST_TOKEN_PATH = 'tmp/token_default.json'

  def before_setup
    super

    @mock_shell = MockShell.new
    Uffizzi::UI::Shell.stubs(:new).returns(@mock_shell)
    Uffizzi::ConfigFile.stubs(:config_path).returns(TEST_CONFIG_PATH)
    Uffizzi::Token.stubs(:token_path).returns(TEST_TOKEN_PATH)
  end

  def before_teardown
    super

    Uffizzi::ConfigFile.delete
    Uffizzi::Token.delete
  end

  def command_options(options)
    Thor::CoreExt::HashWithIndifferentAccess.new(options)
  end

  def render_server_error(error)
    "#{Uffizzi::RESPONSE_SERVER_ERROR_HEADER}#{error}"
  end
end
