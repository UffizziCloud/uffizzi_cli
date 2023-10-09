# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class DevService
  class << self
    include ApiClient

    DEFAULT_REGISTRY_REPO = 'registry.uffizzi.com'

    def check_running_daemon
      return unless File.exist?(pid_path)

      pid = File.read(pid_path)
      File.delete(pid_path) if pid.blank?
      Uffizzi.process.kill(0, pid.to_i)

      Uffizzi.ui.say_error_and_exit("You have already started uffizzi dev as daemon. To stop the process do 'uffizzi dev stop'")
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

    def start_basic_skaffold(config_path, options)
      Uffizzi.ui.say('Start skaffold')
      cmd = build_skaffold_dev_command(config_path, options)

      Uffizzi.ui.popen2e(cmd) do |_stdin, stdout_and_stderr, wait_thr|
        stdout_and_stderr.each { |l| Uffizzi.ui.say(l) }
        wait_thr.value
      end
    end

    def start_demonised_skaffold(config_path, options)
      File.write(logs_path, "Start skaffold\n")
      cmd = build_skaffold_dev_command(config_path, options)

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

    def check_skaffold_existence
      cmd = 'skaffold version'
      stdout_str, stderr_str = Uffizzi.ui.capture3(cmd)

      return if stdout_str.present? && stderr_str.blank?

      Uffizzi.ui.say_error_and_exit(stderr_str)
    rescue StandardError => e
      Uffizzi.ui.say_error_and_exit(e.message)
    end

    def check_skaffold_config_existence(config_path)
      msg = 'A valid dev environment configuration is required. Please provide a valid config,'\
            "\r\n"\
            'or run `skaffold init` to generate a skaffold.yaml configuration.'\
            "\r\n"\
            'See the `uffizzi dev start --help` page for supported configs and usage details.'

      Uffizzi.ui.say_error_and_exit(msg) unless File.exist?(config_path)
    end

    def pid_path
      File.join(Uffizzi::ConfigFile::CONFIG_DIR, 'uffizzi_dev.pid')
    end

    def logs_path
      File.join(Uffizzi::ConfigFile::CONFIG_DIR, 'uffizzi_dev.log')
    end

    def build_skaffold_dev_command(config_path, options)
      cmd = [
        'skaffold dev',
        "--filename='#{config_path}'",
        "--default-repo='#{default_registry_repo(options[:'default-repo'])}'",
        "--kubeconfig='#{default_kubeconfig_path(options[:kubeconfig])}'",
      ]

      cmd.join(' ')
    end

    def default_registry_repo(repo)
      repo || DEFAULT_REGISTRY_REPO
    end

    def default_kubeconfig_path(kubeconfig_path)
      path = kubeconfig_path || KubeconfigService.default_path

      File.expand_path(path)
    end
  end
end
