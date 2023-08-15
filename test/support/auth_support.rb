# frozen_string_literal: true

module AuthSupport
  def sign_in
    cookie = '_uffizzi=test'
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    account = login_body[:user][:default_account]
    data = prepare_config_data(account, cookie)
    data.each_pair { |key, value| Uffizzi::ConfigFile.write_option(key, value) }
  end

  def prepare_config_data(account, cookie)
    {
      account: { 'id' => account[:id], 'name' => account[:name] },
      server: Uffizzi.configuration.server,
      cookie: cookie,
    }
  end

  def sign_out
    Uffizzi::ConfigFile.unset_option(:cookie)
    Uffizzi::ConfigFile.unset_option(:account)
    Uffizzi::ConfigFile.unset_option(:project)
  end
end
