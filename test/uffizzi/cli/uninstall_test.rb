# frozen_string_literal: true

require 'byebug'
require 'psych'
require 'base64'
require 'test_helper'

class UninstallTest < Minitest::Test
  def setup
    @uninstall = Uffizzi::Cli::Uninstall.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')
    helm_values_dir_path = "/tmp/test/#{tmp_dir_name}"
    InstallService.stubs(:helm_values_dir_path).returns(helm_values_dir_path)
  end

  def test_uninstall
    account_id = 1

    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/kubectl config current-context/, stdout: 'my-context')
    @mock_shell.promise_execute(/helm uninstall/, stdout: 'Helm release is uninstalled')
    @mock_prompt.promise_question_answer('Okay to proceed?', 'y')

    body = json_fixture('files/uffizzi/uffizzi_account_controller_settings.json')
    stub_get_account_controller_settings_request(body, account_id)
    stub_delete_account_controller_settings_request(account_id, body[:controller_settings][0][:id])

    @uninstall.controller

    last_message = Uffizzi.ui.last_message
    assert_match('Helm release is uninstalled', last_message)
  end
end
