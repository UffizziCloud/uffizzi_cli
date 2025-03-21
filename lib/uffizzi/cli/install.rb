# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/config_file'
require 'uffizzi/services/kubeconfig_service'
require 'uffizzi/services/account_service'

module Uffizzi
  class Cli::Install < Thor
    include ApiClient

    default_task :controller

    desc 'controller [HOSTNAME]', 'Install uffizzi controller to cluster'
    method_option :namespace, type: :string
    method_option :email, type: :string, required: true
    method_option :context, type: :string
    method_option :issuer, type: :string, enum: ['letsencrypt', 'zerossl']
    method_option :'repo-url', type: :string
    method_option :'node-selector-template', required: false, type: :string
    def controller(hostname)
      Uffizzi::AuthHelper.check_login
      check_account_can_install

      InstallService.kubectl_exists?
      InstallService.helm_exists?

      if options[:context].present? && options[:context] != InstallService.kubeconfig_current_context
        InstallService.set_current_context(options[:context])
      end

      ask_confirmation(options[:namespace])

      uri = parse_hostname(hostname)
      installation_options = build_installation_options(uri)
      check_existence_controller_settings(uri, installation_options)
      helm_values = build_helm_values(installation_options)

      InstallService.create_helm_values_file(helm_values)
      helm_set_repo
      InstallService.helm_install!(namespace)
      InstallService.delete_helm_values_file
      Uffizzi.ui.say('Helm release is deployed')

      controller_setting_params = build_controller_setting_params(uri, installation_options)

      if existing_controller_setting.blank?
        create_controller_settings(controller_setting_params)
        set_account_installation
      end

      Uffizzi.ui.say('Controller settings are saved')
      say_success(uri)
    end

    private

    def helm_set_repo
      return if InstallService.helm_repo_search.present?

      InstallService.helm_repo_add(options[:'repo-url'])
    end

    def build_installation_options(uri)
      {
        uri: uri,
        controller_username: Faker::Lorem.characters(number: 10),
        controller_password: generate_password,
        cert_email: options[:email],
        cluster_issuer: options[:issuer] || InstallService::DEFAULT_CLUSTER_ISSUER,
        node_selector_template: options[:"node-selector-template"],
      }
    end

    def wait_endpoint
      spinner = TTY::Spinner.new('[:spinner] Waiting on IP address...', format: :dots)
      spinner.auto_spin

      endpoint = nil
      try = 0

      loop do
        endpoint = InstallService.get_controller_endpoint(namespace)
        break if endpoint.present?

        if try == 90
          spinner.error

          return 'unknown'
        end

        try += 1
        sleep(2)
      end

      spinner.success

      endpoint
    end

    def build_helm_values(params)
      {
        global: {
          uffizzi: {
            controller: {
              username: params[:controller_username],
              password: params[:controller_password],
            },
          },
        },
        clusterIssuer: params.fetch(:cluster_issuer),
        tlsPerDeploymentEnabled: true.to_s,
        certEmail: params.fetch(:cert_email),
        'ingress-nginx' => {
          controller: {
            ingressClassResource: {
              default: true,
            },
          },
        },
        ingress: {
          hostname: InstallService.build_controller_host(params[:uri].host),
        },
      }.deep_stringify_keys
    end

    def generate_password
      hexatridecimal_base = 36
      length = 8
      rand(hexatridecimal_base**length).to_s(hexatridecimal_base)
    end

    def check_existence_controller_settings(uri, installation_options)
      return if existing_controller_setting.blank?

      Uffizzi.ui.say_error_and_exit('Installation canceled') unless update_and_continue?

      controller_setting_params = build_controller_setting_params(uri, installation_options)
      update_controller_settings(existing_controller_setting[:id], controller_setting_params)
    end

    def ask_confirmation(namespace)
      msg = namespace.present? ? custom_namespace_installation_message(namespace) : default_installation_message
      Uffizzi.ui.say(msg)

      question = 'Okay to proceed?'
      Uffizzi.ui.say_error_and_exit('Installation canceled') unless Uffizzi.prompt.yes?(question)
    end

    def update_and_continue?
      msg = "\r\n"\
            'You already have installation controller params. '\
            "\r\n"\
            'You can update previous params and continue installation or cancel installation.'\
            "\r\n"

      Uffizzi.ui.say(msg)

      question = 'Do you want update the controller settings?'
      Uffizzi.prompt.yes?(question)
    end

    def fetch_controller_settings
      response = get_account_controller_settings(server, account_id)
      return Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)

      response.dig(:body, :controller_settings)
    end

    def set_account_installation
      params = {
        installation_type: AccountService::SELF_HOSTED_CONTROLLER_INSTALLATION_TYPE,
      }

      response = update_account(server, account_name, params)
      Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)
    end

    def update_controller_settings(controller_setting_id, params)
      response = update_account_controller_settings(server, account_id, controller_setting_id, params)
      Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)
    end

    def create_controller_settings(params)
      response = create_account_controller_settings(server, account_id, params)
      unless Uffizzi::ResponseHelper.created?(response)
        Uffizzi::ResponseHelper.handle_failed_response(response)
        raise Uffizzi::Error.new
      end
    end

    def check_account_can_install
      response = check_can_install(server, account_id)
      unless Uffizzi::ResponseHelper.ok?(response)
        Uffizzi::ResponseHelper.handle_failed_response(response)
        raise Uffizzi::Error.new
      end
    end

    def build_controller_setting_params(uri, installation_options)
      {
        url: URI::HTTPS.build(host: InstallService.build_controller_host(uri.host)).to_s,
        managed_dns_zone: uri.host,
        login: installation_options[:controller_username],
        password: installation_options[:controller_password],
        node_selector_template: installation_options[:node_selector_template],
      }
    end

    def say_success(uri)
      endpoint = wait_endpoint

      msg = 'Your Uffizzi controller is ready. To configure DNS,'\
            " create a record for the hostname '*.#{uri.host}' pointing to '#{endpoint}'"
      Uffizzi.ui.say(msg)
    end

    def parse_hostname(hostname)
      uri = URI.parse(hostname)
      host = uri.host || hostname

      case uri
      when URI::HTTP, URI::HTTPS
        uri
      else
        URI::HTTPS.build(host: host)
      end
    end

    def namespace
      options[:namespace] || InstallService::DEFAULT_NAMESPACE
    end

    def server
      @server ||= ConfigFile.read_option(:server)
    end

    def account_id
      @account_id ||= ConfigFile.read_option(:account, :id)
    end

    def account_name
      @account_name ||= ConfigFile.read_option(:account, :name)
    end

    def existing_controller_setting
      @existing_controller_setting ||= fetch_controller_settings[0]
    end

    def default_installation_message
      "\r\n"\
      "This command will install Uffizzi into the 'default' namespace of"\
      " the '#{InstallService.kubeconfig_current_context}' context."\
      "\r\n"\
      "To install in a different place, use options '--namespace' and/or '--context'."\
      "\r\n\r\n"\
      "After installation, new environments created for account '#{account_name}' will be deployed to this host cluster."\
      "\r\n\r\n"
    end

    def custom_namespace_installation_message(namespace)
      "\r\n"\
      "This command will install Uffizzi into the '#{namespace}' namespace of"\
      " the '#{InstallService.kubeconfig_current_context}' context."\
      "\r\n\r\n"\
      "After installation, new environments created for account '#{account_name}' will be deployed to this host cluster."\
      "\r\n\r\n"
    end
  end
end
