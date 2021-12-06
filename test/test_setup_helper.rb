require 'minitest/autorun'
require_relative '../config/uffizzi'

class Minitest::Test

  def before_setup
    Uffizzi::ConfigFile.delete
  end

  def sign_in
    @cookie = "_uffizzi=test"
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    @account_id = login_body[:user][:accounts].first[:id]
    Uffizzi::ConfigFile.create(@account_id, @cookie, Uffizzi.configuration.hostname)
  end
end
