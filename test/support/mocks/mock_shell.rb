# frozen_string_literal: true

class MockShell
  attr_accessor :messages, :output_format

  def initialize
    @messages = []
    @output_enabled = true
  end

  def say(message)
    return unless @output_enabled

    formatted_message = case output_format
                        when 'pretty-json'
                          format_to_pretty_json(message)
                        when 'json'
                          format_to_json(message)
                        when 'github-action'
                          format_to_github_action(message)
                        else
                          message
    end
    @messages << formatted_message
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
    @output_enabled = false
  end

  def enable_stdout
    @output_enabled = true
  end

  def pretty_say(collection, _index = true)
    collection
  end

  private

  def format_to_json(data)
    data.to_json
  end

  def format_to_pretty_json(data)
    JSON.pretty_generate(data)
  end

  def format_to_github_action(data)
    data.reduce('') { |acc, (key, value)| "#{acc}::set-output name=#{key}::#{value}\n" }
  end
end
