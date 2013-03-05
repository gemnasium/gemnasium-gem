require 'net/https'

module Gemnasium
  class Connection
    def initialize
      @connection = Net::HTTP.new(Gemnasium.config.site, Gemnasium.config.use_ssl ? 443 : 80)
      @connection.use_ssl = Gemnasium.config.use_ssl
    end

    def post(path, body, headers = {})
      request = Net::HTTP::Post.new(path, headers.merge('Accept' => 'application/json', 'Content-Type' => 'application/json'))
      request.basic_auth('X', Gemnasium.config.api_key)
      request.body = body
      @connection.request(request)
    end

    def get(path, headers = {})
      request = Net::HTTP::Get.new(path, headers.merge('Accept' => 'application/json', 'Content-Type' => 'application/json'))
      request.basic_auth('X', Gemnasium.config.api_key)
      @connection.request(request)
    end

    # Set the API path for a specific item
    #
    # @param item [String] item the route should point to
    # @return [String] API path
    def api_path_for item
      base = "/api/#{Gemnasium.config.api_version}"

      case item
      when 'base'
        base
      when 'projects'
        "#{base}/profiles/#{Gemnasium.config.profile_name}/projects"
      when 'dependency_files'
        "#{base}/profiles/#{Gemnasium.config.profile_name}/projects/#{Gemnasium.config.project_name}/dependency_files"
      else
        raise "No API path found for #{item}"
      end
    end
  end
end