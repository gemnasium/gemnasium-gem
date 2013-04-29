require 'yaml'

module Gemnasium
  class Configuration
    attr_accessor :site, :api_key, :use_ssl, :profile_name, :project_name, :api_version, :project_branch
    DEFAULT_CONFIG = { site: 'gemnasium.com',
                       use_ssl: true,
                       api_version: 'v2' }

    # Initialize the configuration object from a YAML file
    #
    # @param config_file [String] path to the configuration file
    def initialize config_file
      raise Errno::ENOENT, "Configuration file (#{config_file}) does not exist.\nPlease run `gemnasium install`." unless File.file?(config_file)

      config_hash = DEFAULT_CONFIG.merge!(YAML.load_file(config_file))
      config_hash.each do |k, v|
        writer_method = "#{k}="
        send(writer_method, v) if respond_to?(writer_method)
      end

      raise 'Your configuration file does not contain all mandatory parameters or contain invalid values. Please check the documentation.' unless is_valid?
    end

    private

    # Check that mandatory parameters are not nil and contain valid values
    #
    # @return [Boolean] if configuration is valid
    def is_valid?
      site_option_valid               = !site.nil? && !site.empty?
      api_key_option_valid            = !api_key.nil? && !api_key.empty?
      use_ssl_option_valid            = !use_ssl.nil? && !!use_ssl == use_ssl # Check this is a boolean
      api_version_option_valid        = !api_version.nil? && !api_version.empty?
      profile_name_option_valid       = !profile_name.nil? && !profile_name.empty?
      project_name_option_valid       = !project_name.nil? && !project_name.empty?

      site_option_valid && api_key_option_valid && use_ssl_option_valid && api_version_option_valid &&
      profile_name_option_valid && project_name_option_valid
    end
  end
end