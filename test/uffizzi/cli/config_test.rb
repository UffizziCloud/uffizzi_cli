# frozen_string_literal: true

require 'test_helper'
require 'uffizzi'

class ConfigTest < Minitest::Test
  def setup
    @cli = Uffizzi::CLI.new

    sign_in
  end

  def test_list
    result = @cli.config('list')

    assert_equal(result[:account_id], @account_id)
    assert_equal(result[:cookie], @cookie)
    assert_equal(result[:hostname], Uffizzi.configuration.hostname)
  end

  def test_get_without_property
    @cli.config('get')

    assert_equal('No property provided', Uffizzi.ui.last_message)
  end

  def test_get_with_property
    @cli.config('get', 'cookie')

    assert_equal(Uffizzi::ConfigFile.read_option(:cookie), Uffizzi.ui.last_message)
  end

  def test_get_with_wrong_property
    unexisted_property = 'unexisted_property'
    @cli.config('get', unexisted_property)

    assert_equal("The option #{unexisted_property} doesn't exist in config file", Uffizzi.ui.last_message)
  end

  def test_set_without_property_and_value
    @cli.config('set')

    assert_equal("No property provided\nNo value provided", Uffizzi.ui.last_message)
  end

  def test_set_without_value
    @cli.config('set', 'cookie')

    assert_equal('No value provided', Uffizzi.ui.last_message)
  end

  def test_set_with_property_and_value
    new_cookie = '_uffizzi=test2'

    refute_equal(Uffizzi::ConfigFile.read_option(:cookie), new_cookie)

    @cli.config('set', 'cookie', new_cookie)

    assert_equal(Uffizzi::ConfigFile.read_option(:cookie), new_cookie)
  end

  def test_set_without_config
    cookie = '_uffizzi=test'

    Uffizzi::ConfigFile.delete

    @cli.config('set', 'cookie', cookie)

    assert_equal(cookie, Uffizzi::ConfigFile.read_option(:cookie))
  end

  def test_delete_without_property
    @cli.config('delete')

    assert_equal('No property provided', Uffizzi.ui.last_message)
  end

  def test_delete_with_property
    @cli.config('delete', 'cookie')

    refute(Uffizzi::ConfigFile.read_option(:cookie))
  end
end
