# frozen_string_literal: true

module FixtureSupport
  def file_fixture(file_path)
    full_path = "/test/fixtures/#{file_path}"
    File.new(Dir.pwd + full_path)
  end

  def json_fixture(file_path, symbolize_names: true)
    data = file_fixture(file_path).read
    JSON.parse(data, symbolize_names: symbolize_names)
  end
end
