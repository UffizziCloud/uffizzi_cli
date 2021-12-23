# frozen_string_literal: true

require 'test_helper'

class ConfigTest < Minitest::Test

  def setup
    @cli = Uffizzi::CLI.new
    @hostname = "http://web:7000"
    @cookie = "_uffizzi=test"
    @login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    Uffizzi::ConfigFile.create(@login_body, @cookie, @hostname)

    @buffer = StringIO.new
    $stdout = @buffer
  end

  def test_list
    result = @cli.config("list")

    assert_equal(result[:account_id], @login_body[:user][:accounts].first[:id])
    assert_equal(result[:cookie], @cookie)
    assert_equal(result[:hostname], @hostname)
  end


  def test_get_without_property
    result = @cli.config("get")

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, "No property provided")
    refute(result)
  end

  def test_get_with_property
    result = @cli.config("get", "cookie")

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, Uffizzi::ConfigFile.read_option(:cookie))
    refute(result)
  end

  def test_get_with_wrong_property
    unexisted_property = "unexisted_property"
    result = @cli.config("get", unexisted_property)

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, "The option #{unexisted_property} doesn't exist in config file")
    refute(result)
  end

  def test_set_without_property_and_value
    result = @cli.config("set")

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, "No property provided\nNo value provided")
    refute(result)
  end

  def test_set_without_value
    result = @cli.config("set", "cookie")

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, "No value provided")
    refute(result)
  end

  def test_set_with_property_and_value
    new_cookie = "_uffizzi=test2"

    refute_equal(new_cookie, Uffizzi::ConfigFile.read_option(:cookie))

    result = @cli.config("set", "cookie", new_cookie)

    assert_equal(new_cookie, Uffizzi::ConfigFile.read_option(:cookie))
    refute(result)
  end

  def test_delete_without_property
    result = @cli.config("delete")

    $stdout = STDOUT
    @buffer.rewind

    assert_equal(@buffer.read.strip, "No property provided")
    refute(result)
  end

  def test_delete_with_property
    result = @cli.config("delete", "cookie")

    refute(Uffizzi::ConfigFile.read_option(:cookie))
    refute(result)
  end
end
