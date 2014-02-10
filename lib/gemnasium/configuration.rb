require 'yaml'

module Gemnasium
  class Configuration
    attr_accessor :site, :api_key, :use_ssl, :api_version, :project_branch, :ignored_paths

    attr_accessor :project_name # Name is required only to create the project, make it mandatory.
    attr_accessor :project_slug # Slug is required only to push the dependency files, make it optional.
    attr_accessor :profile_name # Keep profile name for backward compatibility with version =< 2.0

    DEFAULT_CONFIG = { 'site' => 'gemnasium.com',
                       'use_ssl' => true,
                       'api_version' => 'v3',
                       'ignored_paths' => [] }

    # Initialize the configuration object from a YAML file
    #
    # @param config_file [String] path to the configuration file
    def initialize config_file
      unless File.file?(config_file)
        raise Errno::ENOENT,
          "Configuration file (#{config_file}) does not exist.\nPlease run `gemnasium install`."
      end
      @path = config_file

      config_hash = DEFAULT_CONFIG.merge(YAML.load_file(config_file))
      config_hash.each do |k, v|
        writer_method = "#{k}="
        if respond_to?(writer_method)
          v = convert_ignored_paths_to_regexp(v) if k.to_s == 'ignored_paths'
          send(writer_method, v)
        end
      end

      raise 'Your configuration file does not contain all mandatory parameters or contain invalid values. Please check the documentation.' unless is_valid?
    end

    # Store a key-value pair in the configuration file with an optional comment.
    # Try to preserve the comments and the indentation of the file.
    # We assume the configuration file already features the given key.
    #
    # @param key [String] key
    # @param value [String] value to store for given key
    # @param comment [String] optional comment
    #
    def store_value!(key, value, comment = nil)
      pattern = /\A:#{ key }:.*\Z/
      new_line = ":#{ key }: #{ value }"
      new_line += " # #{ comment }" if comment

      content = File.readlines(path).map do |line|
        line.strip.sub pattern, new_line
      end.join("\n")

      File.write path, content
    end

    def writable?
      File.writable? path
    end

    private

    attr_reader :path

    # Check that mandatory parameters are not nil and contain valid values
    #
    # @return [Boolean] if configuration is valid
    def is_valid?
      site_option_valid               = !site.nil? && !site.empty?
      api_key_option_valid            = !api_key.nil? && !api_key.empty?
      use_ssl_option_valid            = !use_ssl.nil? && !!use_ssl == use_ssl # Check this is a boolean
      api_version_option_valid        = !api_version.nil? && !api_version.empty?
      project_name_option_valid       = !project_name.nil? && !project_name.empty?
      ignored_paths_option_valid      = ignored_paths.kind_of?(Array)

      site_option_valid && api_key_option_valid && use_ssl_option_valid && api_version_option_valid &&
      project_name_option_valid && ignored_paths_option_valid
    end

    def convert_ignored_paths_to_regexp(paths)
      return [] unless paths.kind_of? Array

      paths.inject([]) do |regexp_array, path|
        path = path.insert(0,'^')       # All path start from app root
                   .gsub('*','[^/]+')   # Replace `*` to whatever char except slash
                   .gsub('.','\.')      # Escape dots
        regexp_array << Regexp.new(path)
      end
    end
  end
end
