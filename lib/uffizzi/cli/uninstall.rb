# frozen_string_literal: true

require 'uffizzi'
require 'uffizzi/config_file'
require 'uffizzi/services/install_service'
require 'uffizzi/services/kubeconfig_service'

module Uffizzi
  class Cli::Uninstall < Thor
    include ApiClient

    default_task :controller

    desc 'controller [HOSTNAME]', 'Install uffizzi controller to cluster'
    method_option :namespace, type: :string
    method_option :context, type: :string
    def controller
      Uffizzi::AuthHelper.check_login

      InstallService.kubectl_exists?
      InstallService.helm_exists?

      if options[:context].present? && options[:context] != InstallService.kubeconfig_current_context
        InstallService.set_current_context(options[:context])
      end

      ask_confirmation
      delete_controller_settings
      unset_account_installation
      InstallService.helm_uninstall!(namespace)

      helm_unset_repo
    end

    private

    def helm_unset_repo
      return if InstallService.helm_repo_search.blank?

      InstallService.helm_repo_remove
    end

    def ask_confirmation
      msg = "This command will uninstall Uffizzi from the '#{namespace}'"\
            " namespace of the '#{InstallService.kubeconfig_current_context}' context."\
            "\r\n"\
            "To uninstall a different installation, use options '--namespace' and/or '--context'."\
            "\r\n\r\n"\
            "After uninstalling, new environments created for account '#{account_name}'"\
            "\r\n"\
            'will be deployed to Uffizzi Cloud (app.uffizzi.com).'\
            "\r\n\r\n"

      Uffizzi.ui.say(msg)

      question = 'Okay to proceed?'
      Uffizzi.ui.say_error_and_exit('Uninstallation canceled') unless Uffizzi.prompt.yes?(question)
    end

    def fetch_controller_settings
      response = get_account_controller_settings(server, account_id)
      return Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)

      response.dig(:body, :controller_settings)
    end

    def delete_controller_settings
      return if existing_controller_setting.blank?

      response = delete_account_controller_settings(server, account_id, existing_controller_setting[:id])

      if ResponseHelper.no_content?(response)
        Uffizzi.ui.say('Controller settings deleted')
      else
        ResponseHelper.handle_failed_response(response)
      end
    end

    def unset_account_installation
      params = {
        installation_type: nil,
      }

      response = update_account(server, account_name, params)
      Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)
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
  end
end
