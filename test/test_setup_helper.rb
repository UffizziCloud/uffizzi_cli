require 'minitest/autorun'
require 'minitest/hooks/default'
require_relative '../config/config'

class Minitest::Test
  def sign_in
    @cookie = "_uffizzi=test"
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    @account_id = login_body[:user][:accounts].first[:id]
    Uffizzi::ConfigFile.create(@account_id, @cookie, Uffizzi.configuration.hostname)
  end
end