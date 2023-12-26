# frozen_string_literal: true

require 'psych'
require 'base64'
require 'test_helper'

class InstallTest < Minitest::Test
  def setup
    @install = Uffizzi::Cli::Install.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')
    helm_values_dir_path = "/tmp/test/#{tmp_dir_name}"
    InstallService.stubs(:helm_values_dir_path).returns(helm_values_dir_path)
  end

  def test_install
    host = 'my-host.com'
    account_id = 1
    account_name = 'some_account'
    Uffizzi::ConfigFile.write_option(:account, { 'id' => account_id, 'name' => account_name })

    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/kubectl config current-context/, stdout: 'my-context')
    @mock_shell.promise_execute(/helm upgrade/, stdout: { info: { status: 'deployed' } }.to_json)
    ingress_answer = {
      items: [
        metadata: {
          name: InstallService::INGRESS_NAME,
        },
        status: {
          loadBalancer: {
            ingress: [{ ip: '34.31.68.232' }],
          },
        },
      ],
    }

    cert_request_answer = {
      items: [
        metadata: {
          name: host,
        },
        status: {
          conditions: [
            { type: 'Approved', status: 'True' },
            { type: 'Ready', status: 'True' },
          ],
        },
      ],
    }

    @mock_shell.promise_execute(/kubectl get ingress/, stdout: ingress_answer.to_json)
    @mock_shell.promise_execute(/kubectl get certificaterequests/, stdout: cert_request_answer.to_json)
    @mock_prompt.promise_question_answer('Okay to proceed?', 'y')

    empty_controller_settings_body = json_fixture('files/uffizzi/uffizzi_account_controller_settings_empty.json')
    account_body = json_fixture('files/uffizzi/uffizzi_account_success_with_installation.json')
    stub_get_account_controller_settings_request(empty_controller_settings_body, account_id)
    stub_create_account_controller_settings_request({}, account_id)
    stub_update_account_success(account_body, account_name)

    @install.options = command_options(email: 'admin@my-domain.com')
    @install.controller(host)

    last_message = Uffizzi.ui.last_message
    assert_match('Your Uffizzi controller is ready', last_message)
  end

  def test_install_if_settgins_exists
    host = 'my-host.com'
    account_id = 1

    @mock_shell.promise_execute(/kubectl version/, stdout: '1.23.00')
    @mock_shell.promise_execute(/helm version/, stdout: '3.00')
    @mock_shell.promise_execute(/helm search repo/, stdout: [].to_json)
    @mock_shell.promise_execute(/helm repo add/, stdout: 'ok')
    @mock_shell.promise_execute(/kubectl config current-context/, stdout: 'my-context')
    @mock_shell.promise_execute(/helm upgrade/, stdout: { info: { status: 'deployed' } }.to_json)
    ingress_answer = {
      items: [
        metadata: {
          name: InstallService::INGRESS_NAME,
        },
        status: {
          loadBalancer: {
            ingress: [{ ip: '34.31.68.232' }],
          },
        },
      ],
    }

    cert_request_answer = {
      items: [
        metadata: {
          name: host,
        },
        status: {
          conditions: [
            { type: 'Approved', status: 'True' },
            { type: 'Ready', status: 'True' },
          ],
        },
      ],
    }

    @mock_shell.promise_execute(/kubectl get ingress/, stdout: ingress_answer.to_json)
    @mock_shell.promise_execute(/kubectl get certificaterequests/, stdout: cert_request_answer.to_json)
    @mock_prompt.promise_question_answer('Okay to proceed?', 'y')
    @mock_prompt.promise_question_answer('Do you want update the controller settings?', 'y')

    account_controller_settings_body = json_fixture('files/uffizzi/uffizzi_account_controller_settings.json')
    stub_get_account_controller_settings_request(account_controller_settings_body, account_id)
    stub_update_account_controller_settings_request(account_controller_settings_body, account_id,
                                                    account_controller_settings_body[:controller_settings][0][:id])

    @install.options = command_options(email: 'admin@my-domain.com')
    @install.controller(host)

    last_message = Uffizzi.ui.last_message
    assert_match('Your Uffizzi controller is ready', last_message)
  end
end
