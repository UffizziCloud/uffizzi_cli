# frozen_string_literal: true

module AuthSupport
  def sign_in
    cookie = '_uffizzi=test'
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    account_id = login_body[:user][:default_account][:id].to_s
    data = prepare_config_data(account_id, cookie)
    data.each_pair { |key, value| Uffizzi::ConfigFile.write_option(key, value) }
  end

  def prepare_config_data(account_id, cookie)
    {
      account_id: account_id,
      server: Uffizzi.configuration.server,
      cookie: cookie,
    }
  end

  def sign_out
    Uffizzi::ConfigFile.unset_option(:cookie)
    Uffizzi::ConfigFile.unset_option(:account_id)
  end
end
