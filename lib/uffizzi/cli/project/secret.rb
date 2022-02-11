module Uffizzi
  class Cli::Project::Secret
    include ApiClient

    def initialize(command)
      @command = command
    end

    def run
      return Uffizzi::ui.say('You are not logged in.') unless Uffizzi::AuthHelper.signed_in?

      case @command
      when 'list'
        handle_list_command
      when 'create'
        handle_create_command
      when 'delete'
        handle_delete_command
      end
    end

    def handle_list_command
      fetch_secrets(hostname, project_slug, params)
    end

    def handle_create_command
    end

    def handle_delete_command
    end
  end
end
