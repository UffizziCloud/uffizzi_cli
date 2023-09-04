# frozen_string_literal: true

require 'psych'
require 'base64'
require 'test_helper'

class InstallTest < Minitest::Test
  def setup
    @install = Uffizzi::Cli::Install.new

    tmp_dir_name = (Time.now.utc.to_f * 100_000).to_i
    helm_values_path = "/tmp/test/#{tmp_dir_name}/helm_values.yaml"
    Uffizzi::ConfigFile.stubs(:config_path).returns(helm_values_path)
  end

  def test_install_by_wizard
    @mock_prompt.promise_question_answer('Uffizzi use a wildcard tls certificate. Do you have it?', 'n')
    @mock_prompt.promise_question_answer('Do you want to add wildcard certificate later?', 'y')
    @mock_prompt.promise_question_answer('Namespace: ', 'uffizzi')
    @mock_prompt.promise_question_answer('Domain: ', 'my-domain.com')
    @mock_prompt.promise_question_answer('User email: ', 'admin@my-domain.com')
    @mock_prompt.promise_question_answer('User password: ', 'password')
    @mock_prompt.promise_question_answer('Controller password: ', 'password')
    @mock_prompt.promise_question_answer('Email address for ACME registration: ', 'admin@my-domain.com')
    @mock_prompt.promise_question_answer('Cluster issuer', :first)

    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/helm list/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm upgrade/, stdout: { info: { status: 'deployed' } }.to_json)

    @install.application

    last_message = Uffizzi.ui.last_message
    assert_match('The uffizzi application url is', last_message)
  end

  def test_install_by_options
    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/helm upgrade/, stdout: { info: { status: 'deployed' } }.to_json)

    @install.options = command_options(domain: 'my-domain.com', 'without-wildcard-tls' => true)
    @install.application

    last_message = Uffizzi.ui.last_message
    assert_match('The uffizzi application url is', last_message)
  end
end
