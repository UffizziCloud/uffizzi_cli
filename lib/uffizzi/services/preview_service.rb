# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class PreviewService
  ACTIVITY_ITEM_STATE_FAILED = 'failed'
  ACTIVITY_ITEM_STATE_DEPLOYED = 'deployed'

  class << self
    include ApiClient

    def read_deployment_id(deployment_name)
      return nil unless deployment_name.start_with?('deployment-')
      return nil unless deployment_name.split('-').size == 2

      deployment_id = deployment_name.split('-').last
      return nil if deployment_id.to_i.to_s != deployment_id

      deployment_id
    end

    def run_containers_deploy(project_slug, deployment)
      deployment_id = deployment[:id]
      token = Uffizzi::ConfigFile.read_option(:token)
      params = { id: deployment_id, token: token }

      response = deploy_containers(server_url, project_slug, deployment_id, params)

      if !Uffizzi::ResponseHelper.no_content?(response)
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end

      activity_items = wait_containers_creation(deployment, project_slug)
      wait_containers_deploy(deployment, project_slug, activity_items)
    end

    private

    def server_url
      @server_url ||= Uffizzi::ConfigFile.read_option(:server)
    end

    def wait_containers_creation(deployment, project_slug)
      spinner = TTY::Spinner.new('[:spinner] Creating containers...', format: :dots)
      spinner.auto_spin

      activity_items = []
      loop do
        activity_items = fetch_activity_items(project_slug, deployment[:id])
        break if activity_items.count == deployment[:containers].count

        sleep(5)
      end

      spinner.success

      Uffizzi.ui.say('Done')

      activity_items
    rescue ApiClient::ResponseError => e
      Uffizzi::ResponseHelper.handle_failed_response(e.response)
    end

    def wait_containers_deploy(deployment, project_slug, activity_items)
      spinner = TTY::Spinner::Multi.new('[:spinner] Deploying preview...', format: :dots, style: {
                                          middle: '  ',
                                          bottom: '  ',
                                        })

      containers_spinners = create_containers_spinners(activity_items, spinner)

      loop do
        activity_items = fetch_activity_items(project_slug, deployment[:id])
        update_containers_spinners!(activity_items, containers_spinners)
        break if activity_items.all? { |activity_item| activity_item_finished?(activity_item) }

        sleep(5)
      end

      spinner.success?
    rescue ApiClient::ResponseError => e
      spinner.error

      descriptions = fetch_k8s_containers_descriptions(deployment, project_slug)
      containers_last_state_messages = descriptions.map do |description|
        container_name = "Last State for container '#{description[:container_name]}':"
        states = description[:last_state].map { |k, v| " #{k}: #{v}" }.join("\n")
        [container_name, states].join("\n")
      end

      Uffizzi::ResponseHelper.handle_failed_response(e.response, containers_last_state_messages)
    end

    def create_containers_spinners(activity_items, spinner)
      activity_items.map do |activity_item|
        container_spinner = spinner.register("[:spinner] #{activity_item[:name]}")
        container_spinner.auto_spin
        {
          name: activity_item[:name],
          spinner: container_spinner,
        }
      end
    end

    def update_containers_spinners!(activity_items, containers_spinners)
      finished_activity_items = activity_items.filter { |activity_item| activity_item_finished?(activity_item) }

      finished_activity_items.each do |activity_item|
        container_spinner = containers_spinners.detect { |spinner| spinner[:name] == activity_item[:name] }
        spinner = container_spinner[:spinner]
        case activity_item[:state]
        when ACTIVITY_ITEM_STATE_DEPLOYED
          spinner.success
        when ACTIVITY_ITEM_STATE_FAILED
          spinner.error
        end
      end
    end

    def fetch_activity_items(project_slug, deployment_id)
      response = get_activity_items(server_url, project_slug, deployment_id)
      raise ApiClient::ResponseError.new(response) unless Uffizzi::ResponseHelper.ok?(response)

      response[:body][:activity_items]
    end

    def fetch_k8s_containers_descriptions(deployment, project_slug)
      descriptions = []

      deployment[:containers].each do |container|
        container_name = container[:service_name]
        response = get_k8s_container_description(server_url, project_slug, deployment[:id], container_name)

        Uffizzi::ResponseHelper.handle_failed_response(response) unless Uffizzi::ResponseHelper.ok?(response)
        last_state = response[:body][:last_state]
        next if last_state.nil?

        descriptions << { container_name: container_name, last_state: last_state }
      end

      descriptions
    end

    def activity_item_finished?(activity_item)
      activity_item[:state] == ACTIVITY_ITEM_STATE_DEPLOYED || activity_item[:state] == ACTIVITY_ITEM_STATE_FAILED
    end
  end
end
