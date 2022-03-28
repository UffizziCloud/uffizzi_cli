# frozen_string_literal: true

class MockShell
  attr_accessor :messages

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
end
