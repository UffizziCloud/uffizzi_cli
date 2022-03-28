# frozen_string_literal: true

class PreviewService
  class << self
    def read_deployment_id(deployment_name)
      return nil unless deployment_name.start_with?('deployment-')
      return nil unless deployment_name.split('-').size == 2

      deployment_id = deployment_name.split('-').last
      return nil if deployment_id.to_i.to_s != deployment_id

      deployment_id
    end
  end
end
