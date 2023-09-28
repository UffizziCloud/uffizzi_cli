# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class DevService
  class << self
    include ApiClient

    def check_running_daemon
      return unless File.exist?(pid_path)

      pid = File.read(pid_path)
      File.delete(pid_path) if pid.blank?
      Uffizzi.process.kill(0, pid.to_i)

      Uffizzi.ui.say_error_and_exit("You already start uffizzi dev as daemon. To stop process do 'uffizzi dev stop'")
    rescue Errno::ESRCH
      File.delete(pid_path)
    end

    def start_check_pid_file_existence
      Thread.new do
        loop do
          Uffizzi.process.kill('QUIT', Uffizzi.process.pid) unless File.exist?(pid_path)
          sleep(1)
        end
      end
    end

    def start_demonised_skaffold(config_path)
      File.write(logs_path, "Start skaffold\n")

      cmd = "skaffold dev --filename='#{config_path}'"

      Uffizzi.ui.popen2e(cmd) do |_stdin, stdout_and_stderr, wait_thr|
        File.open(logs_path, 'a') do |f|
          stdout_and_stderr.each do |line|
            f.puts(line)
            f.flush
          end
        end

        wait_thr.value
      end
    end

    def pid_path
      File.join(Uffizzi::ConfigFile::CONFIG_DIR, 'uffizzi_dev.pid')
    end

    def logs_path
      File.join(Uffizzi::ConfigFile::CONFIG_DIR, 'uffizzi_dev.log')
    end
  end
end
