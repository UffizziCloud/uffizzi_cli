# frozen_string_literal: true

require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

class DevService
  class DevEnvironmentConfigNotExist < StandardError
    def initialize
      super('Dev environment config does not exist')
    end
  end

  DEFAULT_REGISTRY_REPO = 'registry.uffizzi.com'
  STARTUP_STATE = 'startup'
  CLUSTER_DEPLOYED_STATE = 'cluster_deployed'

  class << self
    include ApiClient

    def check_no_running_process!
      if process_running?
        Uffizzi.ui.say_error_and_exit("You have already started uffizzi dev. To stop the process do 'uffizzi dev stop'")
      end
    end

    def check_running_process!
      unless process_running?
        Uffizzi.ui.say_error_and_exit('Uffizzi dev is not running')
      end
    end

    def check_environment_exist!
      unless dev_environment_exist?
        reset_config
        Uffizzi.ui.say_error_and_exit('Uffizzi dev does not exist')
      end
    end

    def stop_process
      dev_pid = running_pid
      skaffold_pid = running_skaffold_pid

      begin
        Uffizzi.process.kill('INT', skaffold_pid)
      rescue Errno::ESRCH
      end

      wait_process_stop(skaffold_pid)
      delete_pid

      Uffizzi.process.kill('INT', dev_pid)
    rescue Errno::ESRCH
      delete_pid
    end

    def wait_process_stop(pid)
      loop do
        Uffizzi.process.kill(0, pid)
        sleep(1)
      end
    rescue Errno::ESRCH
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
      Uffizzi.thread.new do
        loop do
          stop_process unless File.exist?(pid_path)
          sleep(1)
        end
      end
    end

    def run_check_cluster_existence(server, account_id, project_slug)
      current_dev_env = dev_environment

      Uffizzi.thread.new do
        loop do
          sleep(2)
          raise DevEnvironmentConfigNotExist unless dev_environment_exist?

          current_cluster_data = account_user_project_dev_cluster(server, account_id, project_slug, current_dev_env[:cluster_name])

          if current_cluster_data.nil? || current_cluster_data[:id] != current_dev_env[:cluster_id]
            clear_after_delete(current_dev_env[:cluster_id], current_dev_env[:encoded_kubeconfig])
            stop_process
          end
        end
      rescue Uffizzi::ServerResponseError
        run_check_cluster_existence(server, account_id, project_slug)
      rescue StandardError => e
        clear_after_delete(current_dev_env[:cluster_id], current_dev_env[:encoded_kubeconfig])
        stop_process
        raise e
      end
    end

    def start_basic_skaffold(config_path, options)
      Uffizzi.ui.say('Start skaffold')
      cmd = build_skaffold_dev_command(config_path, options)

      Uffizzi.signal.trap('INT') {}

      Uffizzi.ui.popen2e(cmd) do |_stdin, stdout_and_stderr, wait_thr|
        pid = wait_thr.pid
        skaffold_pid = find_skaffold_pid(pid)
        save_skaffold_pid(skaffold_pid)
        stdout_and_stderr.each { |l| Uffizzi.ui.say(l) }
        wait_thr.value
      end
    end

    def start_demonised_skaffold(config_path, options)
      File.write(logs_path, "Start skaffold\n")
      cmd = build_skaffold_dev_command(config_path, options)

      Uffizzi.ui.popen2e(cmd) do |_stdin, stdout_and_stderr, wait_thr|
        pid = wait_thr.pid
        skaffold_pid = find_skaffold_pid(pid)
        save_skaffold_pid(skaffold_pid)

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

    def skaffold_pid_path
      File.join(Uffizzi::ConfigFile::CONFIG_DIR, 'skaffold_dev.pid')
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

    def save_pid
      File.write(pid_path, Uffizzi.process.pid)
    end

    def delete_pid
      File.delete(pid_path) if File.exist?(pid_path)
      File.delete(skaffold_pid_path) if File.exist?(skaffold_pid_path)
    end

    def running_skaffold_pid
      return nil.to_i unless File.exist?(skaffold_pid_path)

      File.read(skaffold_pid_path).to_i
    end

    def save_skaffold_pid(pid)
      File.write(skaffold_pid_path, pid)
    end

    def set_dev_environment_config(cluster_name, cluster_id:, config_path:, encoded_kubeconfig:)
      params = { config_path: File.expand_path(config_path), encoded_kubeconfig: encoded_kubeconfig, cluster_id: cluster_id }
      new_dev_environment = Uffizzi::ConfigHelper.set_dev_environment(cluster_name, params)
      Uffizzi::ConfigFile.write_option(:dev_environment, new_dev_environment)
    end

    def set_startup_state
      new_dev_environment = dev_environment.merge(state: STARTUP_STATE)
      Uffizzi::ConfigFile.write_option(:dev_environment, new_dev_environment)
    end

    def set_cluster_deployed_state
      new_dev_environment = dev_environment.merge(state: CLUSTER_DEPLOYED_STATE)
      Uffizzi::ConfigFile.write_option(:dev_environment, new_dev_environment)
    end

    def startup?
      dev_environment[:state] == STARTUP_STATE
    end

    def reset_config
      Uffizzi::ConfigFile.write_option(:dev_environment, {})
    end

    def dev_environment
      Uffizzi::ConfigHelper.dev_environment
    end

    def dev_environment_exist?
      dev_environment[:cluster_name].present? && dev_environment[:cluster_id].present?
    end

    def find_skaffold_pid(pid)
      pid_regex = /\w*#{pid}.*skaffold dev/
      io = Uffizzi.ui.popen('ps -ef')
      processes = io.readlines.select { |l| l.match?(pid_regex) }

      if processes.count.zero?
        raise StandardError.new('Can\'t find skaffold process pid')
      end

      # HACK: For MacOS
      if processes.count == 1
        current_pid = processes[0].gsub(/\s+/, ' ').lstrip.split[1]
        return pid if current_pid.to_s == pid.to_s

        raise StandardError.new('Can\'t find skaffold process pid')
      end

      # HACK: For Linux
      parent_process = processes
        .map { |ps| ps.gsub(/\s+/, ' ').lstrip.split }
        .detect { |ps| ps[2].to_s == pid.to_s }

      parent_process[1]
    end

    def account_user_project_dev_cluster(server, account_id, project_slug, cluster_name = nil)
      q_params = { kind_eq: ClusterService::DEV_CLUSTER_KIND }
      q_params = q_params.merge(name_eq: cluster_name) if cluster_name.present?
      response = get_account_user_project_clusters(server, account_id, project_slug, { q: q_params })

      if Uffizzi::ResponseHelper.ok?(response)
        response[:body][:clusters][0]
      else
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end

    def clear_after_delete(cluster_id, encoded_kubeconfig)
      kubeconfig = ClusterCommonService.parse_kubeconfig(encoded_kubeconfig)
      ClusterDeleteService.exclude_kubeconfig(cluster_id, kubeconfig) if kubeconfig.present?
      reset_config
    end
  end
end
