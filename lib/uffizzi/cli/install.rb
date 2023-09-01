# frozen_string_literal: true

require 'byebug'
require 'uffizzi'
require 'uffizzi/config_file'

module Uffizzi
  class Cli::Install < Thor
    HELM_REPO_NAME = 'uffizzi'
    HELM_DEPLOYED_STATUS = 'deployed'
    CHART_NAME = 'uffizzi-app'
    VALUES_FILE_NAME = 'helm_values.yaml'
    DEFAULT_ISSUER = 'letsencrypt'
    DEFAULT_NAMESPACE = 'default'
    DEFAULT_APP_PREFIX = 'uffizzi'

    desc 'application', 'Install uffizzi to cluster'
    method_option :namespace, type: :string
    method_option :domain, type: :string
    method_option :'user-email', type: :string
    method_option :'acme-email', type: :string
    method_option :'user-password', type: :string
    method_option :'controller-password', type: :string
    method_option :issuer, type: :string, enum: ['letsencrypt', 'zerossl']
    method_option :'wildcard-cert-path', type: :string
    method_option :'wildcard-key-path', type: :string
    method_option :'without-wildcard-tls', type: :boolean
    method_option :repo, type: :string
    method_option :'print-values', type: :boolean
    def application
      run_installation do
        if options.except(:repo, :'print-values').present?
          validate_installation_options
        else
          ask_installation_params
        end
      end
    end

    desc 'wildcard-tls', 'Add wildcard tls from files'
    method_option :domain, type: :string
    method_option :cert, type: :string
    method_option :key, type: :string
    method_option :namespace, type: :string
    def wildcard_tls
      kubectl_exists?

      params = if options.present? && wildcard_tls_options_valid?
        {
          namespace: options[:namespace] || DEFAULT_NAMESPACE,
          domain: options[:domain],
          wildcard_cert_path: options[:cert],
          wildcard_key_path: options[:key],
        }
      else
        namespace = Uffizzi.prompt.ask('Namespace: ', required: true, default: DEFAULT_NAMESPACE)
        domain = Uffizzi.prompt.ask('Domain: ', required: true, default: 'example.com')
        wildcard_cert_paths = ask_wildcard_cert(has_user_wildcard_cert: true)

        { namespace: namespace, domain: domain }.merge(wildcard_cert_paths)
      end

      kubectl_add_wildcard_tls(params)
    end

    private

    def wildcard_tls_options_valid?
      required_options = [:domain, :cert, :key]
      missing_options = required_options - options.symbolize_keys.keys

      return true if missing_options.empty?

      rendered_missing_options = missing_options.map { |o| "'--#{o}'" }.join(', ')

      Uffizzi.ui.say_error_and_exit("No value provided for required options #{rendered_missing_options}")
    end

    def run_installation
      kubectl_exists?
      helm_exists?
      params = yield
      helm_values = build_helm_values(params)
      return Uffizzi.ui.say(helm_values.to_yaml) if options[:'print-values']

      create_helm_values_file(helm_values)
      helm_set_repo unless options[:repo]
      helm_set_release(params.fetch(:namespace))
      kubectl_add_wildcard_tls(params) if params[:wildcard_cert_path] && params[:wildcard_key_path]
      delete_helm_values_file
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
      Uffizzi.ui.say('Start helm release installation')

      release_name = namespace
      repo = options[:repo] || "#{HELM_REPO_NAME}/#{CHART_NAME}"
      cmd = "helm install #{release_name} #{repo}" \
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

    def ask_wildcard_cert(has_user_wildcard_cert: nil)
      has_user_wildcard_cert ||= Uffizzi.prompt.yes?('Uffizzi use a wildcard tls certificate. Do you have it?')

      if has_user_wildcard_cert
        cert_path = Uffizzi.prompt.ask('Path to cert: ', required: true)
        key_path = Uffizzi.prompt.ask('Path to key: ', required: true)

        return { wildcard_cert_path: cert_path, wildcard_key_path: key_path }
      end

      Uffizzi.ui.say('Uffizzi does not work properly without a wildcard certificate.')
      Uffizzi.ui.say('You can add wildcard cert later with command:')
      Uffizzi.ui.say('uffizzi install wildcard-tls --domain your.domain.com --cert /path/to/cert --key /path/to/key')

      {}
    end

    def ask_installation_params
      wildcard_cert_paths = ask_wildcard_cert
      namespace = Uffizzi.prompt.ask('Namespace: ', required: true, default: DEFAULT_NAMESPACE)
      domain = Uffizzi.prompt.ask('Domain: ', required: true, default: 'example.com')
      user_email = Uffizzi.prompt.ask('User email: ', required: true, default: "admin@#{domain}")
      user_password = Uffizzi.prompt.ask('User password: ', required: true, default: generate_password)
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
        controller_password: generate_password,
        cert_email: cert_email,
        cluster_issuer: cluster_issuer,
      }.merge(wildcard_cert_paths)
    end

    def validate_installation_options
      installation_options = build_installation_options

      if options[:'without-wildcard-tls']
        return installation_options.except(:wildcard_cert_path, :wildcard_key_path)
      end

      empty_key = [:'wildcard-cert-path', :'wildcard-key-path'].detect { |k| options[k].nil? }

      if empty_key.present?
        Uffizzi.ui.say_error_and_exit("#{empty_key} is required or use the flag --without-wildcard-tls")
      end
    end

    def build_installation_options
      {
        namespace: options[:namespace] || DEFAULT_NAMESPACE,
        domain: options[:domain],
        user_email: options[:'user-email'] || "admin@#{options[:domain]}",
        user_password: options[:'user-password'] || generate_password,
        controller_password: options[:'controller-password'] || generate_password,
        cert_email: options[:'acme-email'] || options[:'user-email'],
        cluster_issuer: options[:issuer] || DEFAULT_ISSUER,
        wildcard_cert_path: options[:'wildcard-cert-path'],
        wildcard_key_path: options[:'wildcard-key-path'],
      }
    end

    def build_helm_values(params)
      domain = params.fetch(:domain)
      namespace = params.fetch(:namespace)
      app_host = [DEFAULT_APP_PREFIX, domain].join('.')

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
            disabled: true,
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

    def delete_helm_values_file
      File.delete(helm_values_file_path) if File.exist?(helm_values_file_path)
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
