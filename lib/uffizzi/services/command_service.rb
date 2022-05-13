# frozen_string_literal: true

class CommandService
  class << self
    def project_set?(options)
      !options[:project].nil? || (Uffizzi::ConfigFile.exists? && Uffizzi::ConfigFile.option_has_value?(:project))
    end
  end
end
