# frozen_string_literal: true

class ClusterListService
  class << self
    # REFACTOR_ME:
    # Uffizzi.ui.output_format = Uffizzi::UI::Shell::PRETTY_LIST
    # Uffizzi.ui.say(data)
    def render_plain_clusters(clusters)
      clusters.map do |cluster|
        project_name = cluster.dig(:project, :name)

        if project_name.present?
          "- Cluster name: #{cluster[:name].strip} Project name: #{project_name.strip}"
        else
          "- #{cluster[:name]}"
        end
      end.join("\n")
    end
  end
end
