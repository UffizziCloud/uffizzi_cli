# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class DevService
  class << self
    include ApiClient

    DEFAULT_REGISTRY_REPO = 'registry.uffizzi.com'

    def check_no_running_process
      if process_running?
        delete_pid
        Uffizzi.ui.say_error_and_exit("You have already started uffizzi dev. To stop the process do 'uffizzi dev stop'")
      end
    end

    def check_running_process
      unless process_running?
        delete_pid
        Uffizzi.ui.say_error_and_exit('Uffizzi dev is not running')
      end
    end

    def stop_process
      pid = running_pid

      Uffizzi.process.kill('QUIT', pid)
      delete_pid
    rescue Errno::ESRCH
      delete_pid
    end

    def process_running?
      pid = running_pid
      return false unless pid.positive?

      Uffizzi.process.kill(0, pid.to_i)
      true
    rescue Errno::ESRCH
      false
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

    def running_pid
      return nil.to_i unless File.exist?(pid_path)

      File.read(pid_path).to_i
    end

    def delete_pid
      File.delete(pid_path) if File.exist?(pid_path)
    end

    def set_dev_environment_config(cluster_name, config_path, options)
      params = options.merge(config_path: File.expand_path(config_path))
      new_dev_environment = Uffizzi::ConfigHelper.set_dev_environment(cluster_name, params)
      Uffizzi::ConfigFile.write_option(:dev_environment, new_dev_environment)
    end

    def clear_dev_environment_config
      Uffizzi::ConfigFile.write_option(:dev_environment, {})
    end

    def dev_environment
      Uffizzi::ConfigHelper.dev_environment
    end
  end
end
