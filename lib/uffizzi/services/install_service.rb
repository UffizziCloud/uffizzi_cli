# frozen_string_literal: true

require 'uffizzi/response_helper'
require 'uffizzi/clients/api/api_client'

class InstallService
  DEFAULT_HELM_RELEASE_NAME = 'uffizzi'
  INGRESS_NAME = "#{DEFAULT_HELM_RELEASE_NAME}-controller"
  DEFAULT_HELM_REPO_NAME = 'uffizzi'
  DEFAULT_CONTROLLER_CHART_NAME = 'uffizzi-controller'
  HELM_DEPLOYED_STATUS = 'deployed'
  VALUES_FILE_NAME = 'helm_values.yaml'
  DEFAULT_NAMESPACE = 'default'
  DEFAULT_CLUSTER_ISSUER = 'letsencrypt'
  DEFAULT_CONTROLLER_REPO_URL = 'https://uffizzicloud.github.io/uffizzi_controller'
  DEFAULT_CONTROLLER_DOMAIN_PREFIX = 'controller'

  class << self
    include ApiClient

    def kubectl_exists?
      cmd = 'kubectl version -o json'
      execute_command(cmd, say: false).present?
    end

    def helm_exists?
      cmd = 'helm version --short'
      execute_command(cmd, say: false).present?
    end

    def helm_repo_remove
      cmd = "helm repo remove #{DEFAULT_HELM_REPO_NAME}"
      execute_command(cmd, skip_error: true)
    end

    def helm_repo_search
      cmd = "helm search repo #{DEFAULT_HELM_REPO_NAME}/#{DEFAULT_CONTROLLER_CHART_NAME} -o json"

      execute_command(cmd) do |result, err|
        err.present? ? nil : JSON.parse(result)
      end
    end

    def helm_repo_add(repo_url)
      repo_url = repo_url || DEFAULT_CONTROLLER_REPO_URL
      cmd = "helm repo add #{DEFAULT_HELM_REPO_NAME} #{repo_url}"
      execute_command(cmd)
    end

    def helm_install!(namespace)
      Uffizzi.ui.say('Start helm release installation')

      repo = "#{DEFAULT_HELM_REPO_NAME}/#{DEFAULT_CONTROLLER_CHART_NAME}"
      cmd = "helm upgrade #{DEFAULT_HELM_RELEASE_NAME} #{repo}" \
        " --values #{helm_values_file_path}" \
        " --namespace #{namespace}" \
        ' --create-namespace' \
        ' --install' \
        ' --output json'

      res = execute_command(cmd, say: false)
      info = JSON.parse(res)['info']

      return if info['status'] == HELM_DEPLOYED_STATUS

      Uffizzi.ui.say_error_and_exit(info)
    end

    def helm_uninstall!(namespace)
      Uffizzi.ui.say('Start helm release uninstallation')

      cmd = "helm uninstall #{DEFAULT_HELM_RELEASE_NAME} --namespace #{namespace}"

      execute_command(cmd)
    end

    def set_current_context(context)
      cmd = "kubectl config use-context #{context}"
      execute_command(cmd)
    end

    def kubeconfig_current_context
      cmd = 'kubectl config current-context'

      execute_command(cmd, say: false) { |stdout| stdout.present? && stdout.chop }
    end

    def get_controller_ip(namespace)
      cmd = "kubectl get ingress -n #{namespace} -o json"
      res = execute_command(cmd, say: false)
      ingress = JSON.parse(res)['items'].detect { |i| i['metadata']['name'] = INGRESS_NAME }

      return if ingress.blank?

      load_balancers = ingress.dig('status', 'loadBalancer', 'ingress')
      return if load_balancers.blank?

      load_balancers.map { |i| i['ip'] }[0]
    end

    def get_certificate_request(namespace, uri)
      cmd = "kubectl get certificaterequests -n #{namespace} -o json"
      res = execute_command(cmd, say: false)
      certificate_request = JSON.parse(res)['items'].detect { |i| i['metadata']['name'].include?(uri.host) }

      return if certificate_request.nil?

      conditions = certificate_request.dig('status', 'conditions') || []
      conditions.map { |c| c.slice('type', 'status') }
    end

    def build_controller_host(host)
      [DEFAULT_CONTROLLER_DOMAIN_PREFIX, host].join('.')
    end

    def delete_helm_values_file
      File.delete(helm_values_file_path) if File.exist?(helm_values_file_path)
    end

    def create_helm_values_file(values)
      FileUtils.mkdir_p(helm_values_dir_path) unless File.directory?(helm_values_dir_path)
      File.write(helm_values_file_path, values.to_yaml)
    end

    def helm_values_file_path
      File.join(helm_values_dir_path, VALUES_FILE_NAME)
    end

    def helm_values_dir_path
      File.dirname(Uffizzi::ConfigFile.config_path)
    end

    private

    def execute_command(command, say: true, skip_error: false)
      stdout_str, stderr_str, status = Uffizzi.ui.capture3(command)

      return yield(stdout_str, stderr_str) if block_given?

      if !status.success? && !skip_error
        return Uffizzi.ui.say_error_and_exit(stderr_str)
      end

      if !status.success? && skip_error
        return Uffizzi.ui.say(stderr_str)
      end

      say ? Uffizzi.ui.say(stdout_str) : stdout_str
    rescue Errno::ENOENT => e
      Uffizzi.ui.say_error_and_exit(e.message)
    end
  end
end
