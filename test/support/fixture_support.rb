# frozen_string_literal: true

module FixtureSupport
  def file_fixture(file_path)
    full_path = File.join(Dir.pwd, 'test', 'fixtures', file_path)
    File.new(full_path)
  end

  def json_fixture(file_path, symbolize_names: true)
    data = file_fixture(file_path).read
    JSON.parse(data, symbolize_names: symbolize_names)
  end
end
