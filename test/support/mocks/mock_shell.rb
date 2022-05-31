# frozen_string_literal: true

class MockShell
  attr_accessor :messages, :output_format

  def initialize
    @messages = []
  end

  def say(message)
    @messages << message
  end

  def last_message
    @messages.last
  end

  def ask(answer, *_args)
    answer
  end

  def print_table(table_data)
    table_data
  end

  def print_in_columns(columns_data)
    columns_data
  end

  def describe_project(project)
    say(project)
  end

  def disable_stdout
    true
  end

  def output(data)
    case output_format
    when 'json'
      say(data.to_json)
    when 'github-action'
      data.each_key do |key|
        say("::set-output name=#{key}::#{data[key]}")
      end
    end
  end

  def pretty_say(collection, _index = true)
    collection
  end
end
