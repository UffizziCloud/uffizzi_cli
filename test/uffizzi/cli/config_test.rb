# frozen_string_literal: true

require 'test_helper'
require 'uffizzi'

class ConfigTest < Minitest::Test
  def setup
    @config = Uffizzi::Cli::Config.new

    sign_in
  end

  def test_list
    result = @config.list

    assert_equal(result[:account], Uffizzi::ConfigFile.read_option(:account))
    assert_equal(result[:cookie], Uffizzi::ConfigFile.read_option(:cookie))
    assert_equal(result[:server], Uffizzi.configuration.server)
  end

  def test_get_with_property
    @config.get_value('cookie')

    assert_equal(Uffizzi::ConfigFile.read_option(:cookie), Uffizzi.ui.last_message)
  end

  def test_get_with_wrong_property
    unexisted_property = 'unexisted_property'
    @config.get_value(unexisted_property)

    assert_equal("The option #{unexisted_property} doesn't exist in config file", Uffizzi.ui.last_message)
  end

  def test_set_with_property_and_value
    new_cookie = '_uffizzi=test2'
    property = 'cookie'

    refute_equal(Uffizzi::ConfigFile.read_option(:cookie), new_cookie)

    @config.set(property, new_cookie)

    assert_equal(Uffizzi::ConfigFile.read_option(:cookie), new_cookie)
    assert_equal("Updated property [#{property}]", Uffizzi.ui.last_message)
  end

  def test_set_without_config
    cookie = '_uffizzi=test'
    property = 'cookie'

    Uffizzi::ConfigFile.delete

    @config.set(property, cookie)

    assert_equal(cookie, Uffizzi::ConfigFile.read_option(:cookie))
    assert_equal("Updated property [#{property}]", Uffizzi.ui.last_message)
  end

  def test_unset_property
    property = 'cookie'

    assert(Uffizzi::ConfigFile.option_has_value?(:cookie))

    @config.unset(property)

    refute(Uffizzi::ConfigFile.option_has_value?(:cookie))
    assert_equal("Unset property [#{property}]", Uffizzi.ui.last_message)
  end

  def test_setup
    Uffizzi::ConfigFile.unset_option(:server)
    Uffizzi::ConfigFile.unset_option(:username)

    refute(Uffizzi::ConfigFile.option_has_value?(:server))
    refute(Uffizzi::ConfigFile.option_has_value?(:username))

    @config.setup

    assert(Uffizzi::ConfigFile.option_has_value?(:server))
    assert(Uffizzi::ConfigFile.option_has_value?(:username))
    assert_equal('To login, run: uffizzi login', Uffizzi.ui.last_message)
  end
end
