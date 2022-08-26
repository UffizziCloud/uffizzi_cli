# frozen_string_literal: true

class ProjectService
  class << self
    def describe_project(project, output_format)
      json_format?(output_format) ? output_in_json(project) : output_in_pretty_format(project)
    end

    def select_active_deployments(project)
      project[:deployments].select { |deployment| deployment[:state] == 'active' }
    end

    private

    def json_format?(output_format)
      output_format == 'json'
    end

    def output_in_json(data)
      Uffizzi.ui.say(data.to_json)
    end

    def output_in_pretty_format(project)
      Uffizzi.ui.say("Project name: #{project[:name]}")
      Uffizzi.ui.say("Project slug: #{project[:slug]}")
      Uffizzi.ui.say("Description: #{project[:description]}".strip)
      Uffizzi.ui.say("Account name: #{project[:account][:name]}".strip)
      Uffizzi.ui.say("Created: #{project[:created_at]}")
      default_compose = project[:default_compose].nil? ? nil : project[:default_compose][:source]
      Uffizzi.ui.say("Default compose: #{default_compose}".strip)
      Uffizzi.ui.say('Previews:')
      project[:deployments].each do |deployment|
        Uffizzi.ui.say("  - deployment-#{deployment[:id]} (https://#{deployment[:preview_url]})")
      end
      Uffizzi.ui.say('Secrets:')
      project[:secrets].each do |secret|
        Uffizzi.ui.say("  - #{secret}")
      end
    end
  end
end
