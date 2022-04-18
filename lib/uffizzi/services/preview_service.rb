# frozen_string_literal: true

require 'uffizzi/clients/api/api_client'

class PreviewService
  class << self
    include ApiClient
    def read_deployment_id(deployment_name)
      return nil unless deployment_name.start_with?('deployment-')
      return nil unless deployment_name.split('-').size == 2

      deployment_id = deployment_name.split('-').last
      return nil if deployment_id.to_i.to_s != deployment_id

      deployment_id
    end

    def start_deploy_containers(project_slug, deployment, success_message)
      deployment_id = deployment[:id]
      params = { id: deployment_id }

      response = deploy_containers(Uffizzi::ConfigFile.read_option(:server), project_slug, deployment_id, params)

      if Uffizzi::ResponseHelper.no_content?(response)
        Uffizzi.ui.say(success_message)
        create_deployment(deployment, project_slug)
      else
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end

    private

    def create_deployment(deployment, project_slug)
      spinner = TTY::Spinner.new('[:spinner] Creating containers...', format: :dots)
      spinner.auto_spin

      activity_items = []
      loop do
        response = get_activity_items(Uffizzi::ConfigFile.read_option(:server), project_slug, deployment[:id])
        handle_activity_items_response(response, spinner)
        activity_items = response[:body][:activity_items]
        break if activity_items.count == deployment[:containers].count

        sleep(5)
      end

      spinner.success

      Uffizzi.ui.say('Done')

      display_containers_deploying_status(deployment, project_slug, activity_items)
    end

    def display_containers_deploying_status(deployment, project_slug, activity_items)
      spinner = TTY::Spinner::Multi.new('[:spinner] Deploying preview...', format: :dots, style: {
                                          middle: '  ',
                                          bottom: '  ',
                                        })

      containers_spinners = create_containers_spinners(activity_items, spinner)

      loop do
        response = get_activity_items(Uffizzi::ConfigFile.read_option(:server), project_slug, deployment[:id])
        handle_activity_items_response(response, spinner)
        activity_items = response[:body][:activity_items]
        check_activity_items_state(activity_items, containers_spinners)
        break if activity_items.all? { |activity_item| activity_item[:state] == 'deployed' || activity_item[:state] == 'failed' }

        sleep(5)
      end

      if Uffizzi.ui.output_format.nil?
        Uffizzi.ui.say('Done')
        preview_url = "https://#{deployment[:preview_url]}"
        Uffizzi.ui.say(preview_url) if spinner.success?
      else
        output_data = build_output_data(deployment)
        Uffizzi.ui.output(output_data)
      end
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

    def check_activity_items_state(activity_items, containers_spinners)
      finished_activity_items = activity_items.filter do |activity_item|
        activity_item[:state] == 'deployed' || activity_item[:state] == 'failed'
      end
      finished_activity_items.each do |activity_item|
        container_spinner = containers_spinners.detect { |spinner| spinner[:name] == activity_item[:name] }
        spinner = container_spinner[:spinner]
        case activity_item[:state]
        when 'deployed'
          spinner.success
        when 'failed'
          spinner.error
        end
      end
    end

    def handle_activity_items_response(response, spinner)
      unless Uffizzi::ResponseHelper.ok?(response)
        spinner.error
        Uffizzi::ResponseHelper.handle_failed_response(response)
      end
    end

    def build_output_data(output_data)
      {
        id: "deployment-#{output_data[:id]}",
        url: "https://#{output_data[:preview_url]}",
      }
    end
  end
end
