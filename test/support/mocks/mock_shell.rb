# frozen_string_literal: true

class MockShell
  class ExitError < StandardError; end

  class MockProcessStatus
    def initialize(success)
      @success = success
    end

    def success?
      @success
    end
  end

  class MockProcessWaiter
    def initialize(params = {})
      @pid = params[:pid]
    end

    def value
      MockProcessStatus.new(true)
    end

    def pid
      @pid || generate_pid
    end

    private

    def generate_pid
      (Time.now.utc.to_f * 100_000).to_i
    end
  end

  attr_accessor :messages, :output_format, :stdout_pipe

  def initialize
    @messages = []
    @command_responses = []
    @output_enabled = true
    @stdout_pipe = false
  end

  def say(message)
    return unless @output_enabled

    @messages << format_message(message)
  end

  def say_error_and_exit(message)
    raise ExitError.new(format_message(message))
  end

  def stdout_pipe?
    @stdout_pipe
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

  def popen(command)
    res = get_command_response(command)
    res[:stdout]
  end

  def popen2e(command)
    res = get_command_response(command)
    stdout_and_stderr = [res[:stdout], res[:stderr]]
    process_waiter = MockProcessWaiter.new(res[:waiter])
    block_given? ? yield(nil, stdout_and_stderr, process_waiter) : [nil, stdout_and_stderr, process_waiter]
  end

  def capture3(command, *_params)
    res = get_command_response(command)
    status = MockProcessStatus.new(res[:stderr].nil?)

    [res[:stdout], res[:stderr], status]
  end

  def promise_execute(command, stdout: nil, stderr: nil, waiter: nil)
    @command_responses << { command: command, stdout: stdout, stderr: stderr, waiter: waiter }
  end

  private

  def format_to_json(data)
    data.to_json
  end

  def format_to_pretty_json(data)
    JSON.pretty_generate(data)
  end

  def format_to_github_action(data)
    return '' unless data.is_a?(Hash)

    github_output = ENV.fetch('GITHUB_OUTPUT') { raise 'GITHUB_OUTPUT is not defined' }

    MockFile.open(github_output, 'a') do |f|
      data.each { |(key, value)| f.puts("#{key}=#{value}") }
    end
  end

  def format_to_pretty_list(data)
    case data
    when Array
      data.map { |v| format_to_pretty_list(v) }.join("\n\n")
    when Hash
      data.map { |k, v| "- #{k.to_s.upcase}: #{v}" }.join("\n").strip
    else
      data
    end
  end

  def format_message(message)
    case output_format
    when Uffizzi::UI::Shell::PRETTY_JSON
      format_to_pretty_json(message)
    when Uffizzi::UI::Shell::REGULAR_JSON
      format_to_json(message)
    when Uffizzi::UI::Shell::PRETTY_LIST
      format_to_pretty_list(message)
    else
      message
    end
  end

  def get_command_response(command)
    response_index = @command_responses.index do |command_response|
      case command_response[:command]
      when Regexp
        command_response[:command].match?(command)
      else
        command_response[:command] == command
      end
    end

    stdout = @command_responses[response_index].fetch(:stdout)
    stderr = @command_responses[response_index].fetch(:stderr)
    waiter = @command_responses[response_index].fetch(:waiter)
    @command_responses.delete_at(response_index)

    { stdout: stdout, stderr: stderr, waiter: waiter }
  end
end
