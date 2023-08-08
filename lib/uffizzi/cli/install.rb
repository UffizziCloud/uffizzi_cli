# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/config_file'

module Uffizzi
  class Cli::Install < Thor
    HELM_REPO_NAME = 'uffizzi'
    HELM_DEPLOYED_STATUS = 'deployed'
    CHART_NAME = 'uffizzi-app'
    VALUES_FILE_NAME = 'helm_values.yaml'

    desc 'by-wizard [NAMESPACE]', 'Install uffizzi to cluster'
    def by_wizard(namespace)
      run_installation do
        ask_installation_params(namespace)
      end
    end

    desc 'by-options [NAMESPACE]', 'Install uffizzi to cluster'
    method_option :domain, required: true, type: :string, aliases: '-d'
    method_option :'user-email', required: false, type: :string, aliases: '-e'
    method_option :'acme-email', required: false, type: :string
    method_option :'user-password', required: false, type: :string
    method_option :'controller-password', required: false, type: :string
    method_option :issuer, type: :string, enum: ['letsencrypt', 'zerossl'], default: 'letsencrypt'
    method_option :'wildcard-cert-path', required: false, type: :string
    method_option :'wildcard-key-path', required: false, type: :string
    method_option :'without-wildcard-tls', required: false, type: :boolean
    def by_options(namespace)
      run_installation do
        validate_installation_options(namespace, options)
      end
    end

    desc 'add-wildcard-tls [NAMESPACE]', 'Add wildcard tls from files'
    method_option :cert, required: true, type: :string, aliases: '-c'
    method_option :key, required: true, type: :string, aliases: '-k'
    method_option :domain, required: true, type: :string, aliases: '-d'
    def add_wildcard_tls(namespace)
      kubectl_exists?

      params = {
        namespace: namespace,
        domain: options[:domain],
        wildcard_cert_path: options[:cert],
        wildcard_key_path: options[:key],
      }

      kubectl_add_wildcard_tls(params)
    end

    private

    def run_installation
      kubectl_exists?
      helm_exists?
      params = yield
      helm_values = build_helm_values(params)
      create_helm_values_file(helm_values)
      helm_set_repo
      helm_set_release(params.fetch(:namespace))
      kubectl_add_wildcard_tls(params) if params[:wildcard_cert_path] && params[:wildcard_key_path]
    end

    def kubectl_exists?
      cmd = 'kubectl version -o json'
      execute_command(cmd, say: false).present?
    end

    def helm_exists?
      cmd = 'helm version --short'
      execute_command(cmd, say: false).present?
    end

    def helm_set_repo
      repo = helm_repo_search
      return if repo.present?

      helm_repo_add
    end

    def helm_set_release(namespace)
      releases = helm_release_list(namespace)
      release = releases.detect { |r| r['name'] == namespace }
      if release.present?
        Uffizzi.ui.say_error_and_exit("The release #{release['name']} already exists with status #{release['status']}")
      end

      helm_install(namespace)
    end

    def helm_repo_add
      cmd = "helm repo add #{HELM_REPO_NAME} https://uffizzicloud.github.io/uffizzi"
      execute_command(cmd)
    end

    def helm_repo_search
      cmd = "helm search repo #{HELM_REPO_NAME}/#{CHART_NAME} -o json"

      execute_command(cmd) do |result, err|
        err.present? ? nil : JSON.parse(result)
      end
    end

    def helm_release_list(namespace)
      cmd = "helm list -n #{namespace} -o json"
      result = execute_command(cmd, say: false)

      JSON.parse(result)
    end

    def helm_install(namespace)
      release_name = namespace
      cmd = "helm install #{release_name} #{HELM_REPO_NAME}/#{CHART_NAME}" \
        " --values #{helm_values_file_path}" \
        " --namespace #{namespace}" \
        ' --create-namespace' \
        ' --output json'

      res = execute_command(cmd, say: false)
      info = JSON.parse(res)['info']

      return Uffizzi.ui.say('Helm release is deployed') if info['status'] == HELM_DEPLOYED_STATUS

      Uffizzi.ui.say_error_and_exit(info)
    end

    def kubectl_add_wildcard_tls(params)
      cmd = "kubectl create secret tls wildcard.#{params.fetch(:domain)}" \
            " --cert=#{params.fetch(:wildcard_cert_path)}" \
            " --key=#{params.fetch(:wildcard_key_path)}" \
            " --namespace #{params.fetch(:namespace)}"

      execute_command(cmd)
    end

    def ask_wildcard_cert
      has_user_wildcard_cert = Uffizzi.prompt.yes?('Uffizzi use a wildcard tls certificate. Do you have it?')

      if has_user_wildcard_cert
        cert_path = Uffizzi.prompt.ask('Path to cert: ', required: true)
        key_path = Uffizzi.prompt.ask('Path to key: ', required: true)

        return { wildcard_cert_path: cert_path, wildcard_key_path: key_path }
      end

      add_later = Uffizzi.prompt.yes?('Do you want to add wildcard certificate later?')

      if add_later
        Uffizzi.ui.say('You can set command "uffizzi install add-wildcard-cert [NAMESPACE]'\
                       ' -d your.domain.com -c /path/to/cert -k /path/to/key"')

        { wildcard_cert_path: nil, wildcard_key_path: nil }
      else
        Uffizzi.ui.say('Sorry, but uffizzi can not work correctly without wildcard certificate')
        exit(0)
      end
    end

    def ask_installation_params(namespace)
      wildcard_cert_paths = ask_wildcard_cert
      domain = Uffizzi.prompt.ask('Domain: ', required: true, default: 'example.com')
      user_email = Uffizzi.prompt.ask('User email: ', required: true, default: "admin@#{domain}")
      user_password = Uffizzi.prompt.ask('User password: ', required: true, default: generate_password)
      controller_password = Uffizzi.prompt.ask('Controller password: ', required: true, default: generate_password)
      cert_email = Uffizzi.prompt.ask('Email address for ACME registration: ', required: true, default: user_email)
      cluster_issuers = [
        { name: 'Letsencrypt', value: 'letsencrypt' },
        { name: 'ZeroSSL', value: 'zerossl' },
      ]
      cluster_issuer = Uffizzi.prompt.select('Cluster issuer', cluster_issuers)

      {
        namespace: namespace,
        domain: domain,
        user_email: user_email,
        user_password: user_password,
        controller_password: controller_password,
        cert_email: cert_email,
        cluster_issuer: cluster_issuer,
      }.merge(wildcard_cert_paths)
    end

    def validate_installation_options(namespace, options)
      base_params = {
        namespace: namespace,
        domain: options[:domain],
        user_email: options[:'user-email'] || "admin@#{options[:domain]}",
        user_password: options[:'user-password'] || generate_password,
        controller_password: options[:'controller-password'] || generate_password,
        cert_email: options[:'acme-email'] || options[:'user-email'],
        cluster_issuer: options[:issuer],
        wildcard_cert_path: nil,
        wildcard_key_path: nil,
      }

      return base_params if options[:'without-wildcard-tls']

      empty_key = [:'wildcard-cert-path', :'wildcard-key-path'].detect { |k| options[k].nil? }

      if empty_key.present?
        return Uffizzi.ui.say_error_and_exit("#{empty_key} is required or use the flag without-wildcard-tls")
      end

      wildcard_params = {
        wildcard_cert_path: options[:'wildcard-cert-path'],
        wildcard_key_path: options[:'wildcard-key-path'],
      }

      base_params.merge(wildcard_params)
    end

    def build_helm_values(params)
      domain = params.fetch(:domain)
      namespace = params.fetch(:namespace)
      app_host = ['app', domain].join('.')

      {
        app_url: "https://#{app_host}",
        webHostname: app_host,
        allowed_hosts: app_host,
        managed_dns_zone_dns_name: domain,
        global: {
          uffizzi: {
            firstUser: {
              email: params.fetch(:user_email),
              password: params.fetch(:user_password),
            },
            controller: {
              password: params.fetch(:controller_password),
            },
          },
        },
        'uffizzi-controller' => {
          ingress: {
            hostname: "controller.#{domain}",
          },
          clusterIssuer: params.fetch(:cluster_issuer),
          certEmail: params.fetch(:cert_email),
          'ingress-nginx' => {
            controller: {
              extraArgs: {
                'default-ssl-certificate' => "#{namespace}/wildcard.#{domain}",
              },
            },
          },
        },
      }.deep_stringify_keys
    end

    def execute_command(command, say: true)
      stdout_str, stderr_str, status = Uffizzi.ui.execute(command)

      return yield(stdout_str, stderr_str) if block_given?

      Uffizzi.ui.say_error_and_exit(stderr_str) unless status.success?

      say ? Uffizzi.ui.say(stdout_str) : stdout_str
    rescue Errno::ENOENT => e
      Uffizzi.ui.say_error_and_exit(e.message)
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

    def generate_password
      hexatridecimal_base = 36
      length = 8
      rand(hexatridecimal_base**length).to_s(hexatridecimal_base)
    end
  end
end
