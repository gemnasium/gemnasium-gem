require 'json'
require 'gemnasium/connection'
require 'gemnasium/configuration'
require 'gemnasium/dependency_files'
require 'gemnasium/errors'

module Gemnasium
  class << self

    # Push dependency files to Gemnasium
    # @param options [Hash] Parsed options from the command line. Options supported:
    #             * :project_path       - Path to the project (required)
    def push options
      @config = load_config(options[:project_path])
      ensure_config_is_up_to_date!

      unless current_branch == @config.project_branch
        message = "Dependency files updated but not on tracked branch (#{@config.project_branch}), ignoring...\n"
        if options[:ignore_branch]
          notify message, :blue
        else
          quit_because_of(message)
        end
      end

      unless has_project_slug?
        quit_because_of('Project slug not defined. Please create a new project or "resolve" the name of an existing project.')
      end

      dependency_files_hashes = DependencyFiles.get_sha1s_hash(options[:project_path])
      quit_because_of("No supported dependency files detected.") if dependency_files_hashes.empty?
      notify "#{dependency_files_hashes.keys.count} supported dependency file(s) found: #{dependency_files_hashes.keys.join(', ')}"

      # Ask to Gemnasium server which dependency file should be uploaded (new or modified)
      comparison_results = request("#{connection.api_path_for('dependency_files')}/compare", dependency_files_hashes)
      files_to_upload = comparison_results['to_upload']
      deleted_files = comparison_results['deleted']
      notify "#{deleted_files.count} deleted file(s): #{deleted_files.join(', ')}", :blue unless deleted_files.empty?

      unless files_to_upload.empty?
        notify "#{files_to_upload.count} file(s) to upload: #{files_to_upload.join(', ')}"

        # Upload requested dependency files content
        upload_summary = request("#{connection.api_path_for('dependency_files')}/upload", DependencyFiles.get_content_to_upload(options[:project_path], files_to_upload))
        notify "Added dependency files: #{upload_summary['added']}", :green
        notify "Updated dependency files: #{upload_summary['updated']}", :green
        notify "Unchanged dependency files: #{upload_summary['unchanged']}", :blue unless upload_summary['unchanged'].empty?
        notify "Unsupported dependency files: #{upload_summary['unsupported']}", :blue unless upload_summary['unsupported'].empty?
      else
        notify "The project's dependency files are up-to-date.", :blue
      end
    rescue => exception
      quit_because_of(exception.message)
    end

    # Install needed file(s) to run gemnasium command
    #
    # @param options [Hash] Parsed options from the command line. Options supported:
    #             * :install_rake_task  - Install a rake task to the project
    #             * :install_git_hook   - Install a git post-commit hook
    #             * :project_path       - Path to the project (required)
    def install options
      require 'fileutils'

      # Install config file
      config_file_dir   = "#{options[:project_path]}/config"

      unless File.exists? config_file_dir
        notify "Creating config directory"
        FileUtils.mkdir_p config_file_dir
      end

      # Try to add config/gemnasium.yml to .gitignore
      if File.exists? "#{options[:project_path]}/.gitignore"
        File.open("#{options[:project_path]}/.gitignore", 'a+') do |f|
          f.write("\n# Gemnasium gem configuration file\nconfig/gemnasium.yml") unless f.read.include? 'config/gemnasium.yml'
          notify "Configuration file added to your project's .gitignore."
        end
      end

      notify 'Please fill configuration file with accurate values.', :blue if copy_template('gemnasium.yml', "#{config_file_dir}/gemnasium.yml")

      # Install git hook
      if options[:install_git_hook]
        notify ''
        if File.exists? "#{options[:project_path]}/.git/hooks"
          copy_template('post-commit', "#{options[:project_path]}/.git/hooks/post-commit")
        else
          notify "#{options[:project_path]} is not a git repository. Try to run `git init`.", :red
        end
      end

      # Install rake task
      if options[:install_rake_task]
        notify ''
        if !File.exists? "#{options[:project_path]}/Rakefile"
          notify "Rakefile not found.", :red
        else
          rake_file_dir = "#{options[:project_path]}/lib/tasks"

          unless File.exists? rake_file_dir
            notify "Creating lib/tasks directory"
            FileUtils.mkdir_p rake_file_dir
          end

          if copy_template('gemnasium.rake', "#{rake_file_dir}/gemnasium.rake")
            notify 'Usage:', :blue
            notify "\trake gemnasium:push \t\t- to push your dependency files", :blue
            notify "\trake gemnasium:create \t\t- to create your project on Gemnasium", :blue
            notify "\trake gemnasium:migrate \t\t- to migrate your configuration file", :blue
            notify "\trake gemnasium:resolve \t\t- to resolve the project name to an existing project", :blue
          end
        end
      end
    end

    # Create the project on Gemnasium
    #
    # @param options [Hash] Parsed options from the command line. Options supported:
    #             * :project_path       - Path to the project (required)
    def create_project options
      @config = load_config(options[:project_path])
      ensure_config_is_up_to_date!

      if has_project_slug?
        quit_because_of("You already have a project slug refering to an existing project. Please remove this project slug from your configuration file to create a new project.")
      end

      project_params = { name: @config.project_name, branch: @config.project_branch}

      result = request("#{connection.api_path_for('projects')}", project_params)
      project_name, project_slug, remaining_slot_count = result.values_at 'name', 'slug', 'remaining_slot_count'

      notify "Project `#{ project_name }` successfully created.", :green
      notify "Project slug is `#{ project_slug }`.", :green
      notify "Remaining private slots: #{ remaining_slot_count }", :blue

      if @config.writable?
        @config.store_value!(:project_slug, project_slug, "This unique project slug has been set by `gemnasium create`.")
        notify "Your configuration file has been updated."
      else
        notify "Configuration file cannot be updated. Please edit the file and update the project slug manually."
      end

    rescue => exception
      quit_because_of(exception.message)
    end

    # Migrate the configuration file
    #
    # @param options [Hash] Parsed options from the command line. Options supported:
    #             * :project_path       - Path to the project (required)
    #
    def migrate options
      @config = load_config(options[:project_path])

      if @config.needs_to_migrate?
        @config.migrate!
        notify "Your configuration has been updated.", :green
        notify "Run `gemnasium resolve` if your config is related to an existing project."
        notify "Run `gemnasium create` if you want to create a new project on Gemnasium."
      else
        notify "Your configuration file is already up-to-date.", :green
      end
    end

    # Find and store the project slug matching the given project name.
    #
    # @param options [Hash] Parsed options from the command line. Options supported:
    #             * :project_path       - Path to the project (required)
    #
    def resolve_project options
      @config = load_config(options[:project_path])
      ensure_config_is_up_to_date!

      # REFACTOR: similar code in #create_project
      if has_project_slug?
        quit_because_of("You already have a project slug refering to an existing project. Please remove this project slug from your configuration file.")
      end

      project_name =  @config.project_name
      project_branch =  @config.project_branch || 'master'
      projects = request("#{connection.api_path_for('projects')}")

      candidates = projects.select do |project|
        project['name'] == project_name && project['origin'] == 'offline' && project['branch'] == project_branch
      end

      criterias = "name `#{ project_name }` and branch `#{ project_branch }`"
      if candidates.size == 0
        quit_because_of("You have no off-line project matching #{ criterias }.")
      elsif candidates.size > 1
        quit_because_of("You have more than one off-line project matching #{ criterias }.")
      end

      project = candidates.first
      project_slug = project['slug']
      notify "Project slug is `#{ project_slug }`.", :green

      # REFACTOR: similar code in #create_project
      if @config.writable?
        @config.store_value!(:project_slug, project_slug, "This unique project slug has been set by `gemnasium resolve`.")
        notify "Your configuration file has been updated."
      else
        notify "Configuration file cannot be updated. Please edit the file and update the project slug manually."
      end

    rescue => exception
      quit_because_of(exception.message)
    end


    def config
      @config || quit_because_of('No configuration file loaded')
    end

    private

    def has_project_slug?
      !@config.project_slug.nil?
    end

    # Quit with an error message if the config file needs a migration.
    #
    def ensure_config_is_up_to_date!
      if @config.needs_to_migrate?
        quit_because_of('Your configuration file is not compatible with this version. Please run the `migrate` command first.')
      end
    end

    # Issue a HTTP request
    #
    # @params path [String] Path of the request
    #         parameters [Hash] Parameters to send a POST request
    def request(path, parameters = {})
      if parameters.empty?
        response = connection.get(path)
      else
        response = connection.post(path, JSON.generate(parameters))
      end

      raise Gemnasium::InvalidApiKeyError if response.code.to_i == 401

      response_body = JSON.parse(response.body)

      if response.code.to_i / 100 == 2
        return {} if response_body.empty?
        result = response_body
      else
        if error = "#{response_body['error']}_error".split('_').collect(&:capitalize).join
          raise Gemnasium.const_get(error), response_body['message']
        else
          quit_because_of 'An unknown error has been returned by the server. Please contact Gemnasium support : http://support.gemnasium.com'
        end
      end
    end

    # Create a connection
    def connection
      @connection ||= Connection.new
    end

    # Load config from config file
    #
    # @param config_file [String] path to the project
    # @return [Hash] config options
    def load_config project_path
      @config ||= Configuration.new("#{project_path}/config/gemnasium.yml")
    rescue => exception
      quit_because_of(exception.message)
    end

    # Puts a message to the standard output
    #
    # @param message [String] message to display
    def notify message, color = nil
      if $stdout.tty? && !color.nil?
        color_code = { red: "\e[31m", green: "\e[32m", blue: "\e[34m" }
        reset_color = "\e[0m"

        message = color_code[color] + message + reset_color
      end

      $stdout.puts message
    end

    # Abort the program and colorize the message if $stderr is tty
    #
    # @param error_message [String] message to be puts to $stderr
    def quit_because_of(error_message)
      error_message = "\e[31m#{error_message}\e[0m" if $stderr.tty?
      abort error_message
    end

    # Get the current git branch
    #
    # @return [String] name of the current branch
    def current_branch
      branch = `git branch 2>/dev/null`.split("\n").delete_if { |branch| branch.chars.first != "*" }.first
      branch.gsub("* ","") unless branch.nil?
    end

    # Copy a template file
    #
    # @param file [String] template to copy
    #        target_path [String] location where to copy the template
    def copy_template(file, target_path)
      if File.exists? target_path
        notify "The file #{target_path} already exists"
      else
        template_file = File.expand_path("#{File.dirname(__FILE__)}/templates/#{file}")
        FileUtils.cp template_file, target_path

        if File.exists? target_path
          notify "File created in #{target_path}", :green

          return true
        else
          notify "Could not install #{file} file.", :red
        end
      end

      false
    end
  end
end
