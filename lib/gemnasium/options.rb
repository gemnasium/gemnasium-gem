require 'optparse'

module Gemnasium
  class Options

    # Parse arguments from command line
    #
    # @param args [Array] arguments from command line
    # @return [Hash, OptionParser] hash of the parsed options & Option parser to get --help message
    def self.parse args
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = 'Usage: gemnasium [options]'

        opts.on '-v', '--version', 'Show Gemnasium version' do
          options[:show_version] = true
        end

        opts.on '-h', '--help', 'Display this message' do
          options[:show_help] = true
        end

        opts.separator ''
        opts.separator <<-HELP_MESSAGE
Available commands are:
  create   :   Create or update project on Gemnasium
  install  :   Install the necessary config file
  push     :   Push your dependency files to Gemnasium

See `gemnasium COMMAND --help` for more information on a specific command.
        HELP_MESSAGE
      end

      subcommands = {
        'create'  => OptionParser.new do |opts|
          opts.banner = 'Usage: gemnasium create [options]'

          opts.on('--force', "Force overwriting project's attributes if it already exists") do
            options[:overwrite_attr] = true
          end

          opts.on '-h', '--help', 'Display this message' do
            options[:show_help] = true
          end
        end,
        'install' => OptionParser.new do |opts|
          opts.banner = 'Usage: gemnasium install [options]'

          opts.on '--git', 'Create a post-commit hook to run gemnasium push command if a dependency file has been commited' do
            options[:install_git_hook] = true
          end

          opts.on '--rake', 'Create rake task to run Gemnasium' do
            options[:install_rake_task] = true
          end

          opts.on '-h', '--help', 'Display this message' do
            options[:show_help] = true
          end
        end,
        'push'    => OptionParser.new do |opts|
          opts.banner = 'Usage: gemnasium push'

          opts.on '--silent-branch', 'Ignore untracked branches' do
            options[:silent_branch] = true
          end

          opts.on '-h', '--help', 'Display this message' do
            options[:show_help] = true
          end
        end
      }

      global.order! args
      parser = global

      unless (command = args.shift).nil?
        raise OptionParser::ParseError unless subcommands.has_key?(command)
        subcommands[command].order! args
        options[:command] = command
        parser = subcommands[command]
      end

      return options, parser
    end
  end
end
