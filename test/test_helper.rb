# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
ENV['CLI_DEFAULT_KUBECONFIG_PATH'] = '/tmp/.kube/config'
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
require 'uffizzi/services/dev_service'
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
  TEST_CONFIG_DIR = 'tmp/config_default.json'
  TEST_TOKEN_PATH = 'tmp/token_default.json'
  TEST_PID_PATH = 'tmp/dev.pid'
  TEST_SKAFFOLD_PID_PATH = 'tmp/skaffold_dev.pid'
  TEST_DEV_LOGS_PATH = 'tmp/dev-logs.txt'

  def before_setup
    super

    @mock_prompt = MockPrompt.new
    @mock_shell = MockShell.new
    @mock_process = MockProcess.new
    Uffizzi.stubs(:ui).returns(@mock_shell)
    Uffizzi.stubs(:prompt).returns(@mock_prompt)
    Uffizzi.stubs(:process).returns(@mock_process)
    Uffizzi.stubs(:signal).returns(MockSignal)
    Uffizzi.stubs(:thread).returns(MockSignal)
    Uffizzi.stubs(:at_exit).returns(nil)
    Uffizzi.stubs(:launchy).returns(MockLaunchy)
    Uffizzi::ConfigFile.stubs(:config_path).returns(TEST_CONFIG_PATH)
    Uffizzi::Token.stubs(:token_path).returns(TEST_TOKEN_PATH)
    Uffizzi::ConfigFile.stubs(:config_path).returns(TEST_CONFIG_PATH)
    DevService.stubs(:pid_path).returns(TEST_PID_PATH)
    DevService.stubs(:skaffold_pid_path).returns(TEST_SKAFFOLD_PID_PATH)
    DevService.stubs(:logs_path).returns(TEST_DEV_LOGS_PATH)
  end

  def before_teardown
    super

    Uffizzi::ConfigFile.delete
    Uffizzi::Token.delete

    if File.exist?(Uffizzi.configuration.default_kubeconfig_path)
      File.delete(Uffizzi.configuration.default_kubeconfig_path)
    end

    File.delete(TEST_CONFIG_PATH) if File.exist?(TEST_CONFIG_PATH)
    File.delete(TEST_TOKEN_PATH) if File.exist?(TEST_TOKEN_PATH)
    File.delete(TEST_PID_PATH) if File.exist?(TEST_PID_PATH)
    File.delete(TEST_SKAFFOLD_PID_PATH) if File.exist?(TEST_SKAFFOLD_PID_PATH)
    File.delete(TEST_DEV_LOGS_PATH) if File.exist?(TEST_DEV_LOGS_PATH)
  end

  def command_options(options)
    Thor::CoreExt::HashWithIndifferentAccess.new(options)
  end

  def render_server_error(error)
    "#{Uffizzi::RESPONSE_SERVER_ERROR_HEADER}#{error}"
  end

  def tmp_dir_name
    (Time.now.utc.to_f * 100_000).to_i
  end
end
