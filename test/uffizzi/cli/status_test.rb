# frozen_string_literal: true

require 'test_helper'

class StatusTest < Minitest::Test
  def setup
    @status = Uffizzi::Cli::Status.new

    sign_in
    Uffizzi::ConfigFile.write_option(:project, 'uffizzi')
  end

  def test_status
    body = json_fixture('files/uffizzi/uffizzi_account_success_with_one_project.json')
    account_name = Uffizzi::ConfigFile.read_option(:account, :name)
    stubbed_uffizzi_account = stub_uffizzi_account_success(body, account_name)

    @status.describe

    assert_requested(stubbed_uffizzi_account)
    assert_match("API: #{body[:account][:api_url]}", Uffizzi.ui.last_message)
  end
end
