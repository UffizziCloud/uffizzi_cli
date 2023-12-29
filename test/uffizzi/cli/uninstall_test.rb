# frozen_string_literal: true

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
    account_name = 'some_account'
    Uffizzi::ConfigFile.write_option(:account, { 'id' => account_id, 'name' => account_name })

    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/kubectl config current-context/, stdout: 'my-context')
    @mock_shell.promise_execute(/helm uninstall/, stdout: 'Helm release is uninstalled')
    @mock_prompt.promise_question_answer('Okay to proceed?', 'y')

    account_controller_settings = json_fixture('files/uffizzi/uffizzi_account_controller_settings.json')
    account_body = json_fixture('files/uffizzi/uffizzi_account_success_with_one_project.json')
    stub_get_account_controller_settings_request(account_controller_settings, account_id)
    stub_delete_account_controller_settings_request(account_id, account_controller_settings[:controller_settings][0][:id])
    stub_update_account_success(account_body, account_name)

    @uninstall.controller

    last_message = Uffizzi.ui.last_message
    assert_match('Helm release is uninstalled', last_message)
  end
end
