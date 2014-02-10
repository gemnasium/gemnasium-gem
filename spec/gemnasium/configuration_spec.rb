require 'fileutils'
require 'spec_helper'

describe Gemnasium::Configuration do
  describe 'default config' do
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG['site']).to eql 'gemnasium.com' }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG['use_ssl']).to eql true }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG['api_version']).to eql 'v3' }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG['ignored_paths']).to eql [] }
  end

  let(:config_file_path) { 'tmp/config.yml' }
  let(:config) { described_class.new File.expand_path(config_file_path) }

  let(:config_options) do
    {
      api_key: 'api_key',
      project_name: 'gemnasium-gem',
      project_branch: 'master',
      ignored_paths: ['spec/','tmp/*.lock', '*.gemspec']
    }
  end

  def write_config_file
    File.open(config_file_path, 'w+') { |f| f.write(config_options.to_yaml) }
  end

  after do
    File.delete(config_file_path) if File.exist?(config_file_path)
  end

  describe 'initialize' do
    context 'for an inexistant config file' do
      it { expect { Gemnasium::Configuration.new File.expand_path(config_file_path) }.to raise_error Errno::ENOENT }
    end

    context 'for a config file that does exist' do
      before { FileUtils.touch(config_file_path) }

      context 'with missing mandatory values' do
        let(:config_options) {{ project_name: 'gemnasium-gem' }}
        before { write_config_file }

          it { expect { Gemnasium::Configuration.new File.expand_path(config_file_path) }.to raise_error('Your configuration file does not contain all mandatory parameters or contain invalid values. Please check the documentation.') }
      end

      context 'with all mandatory values' do
        let(:config_options) {{ api_key: 'api_key', project_name: 'gemnasium-gem', project_branch: 'master', ignored_paths: ['spec/','tmp/*.lock', '*.gemspec'] }}
        before { write_config_file }

        it { expect(config.api_key).to eql config_options[:api_key] }

        # Keep profile name for backward compatibility with version =< 2.0
        it { expect(config.profile_name).to eql config_options[:profile_name] }

        it { expect(config.project_name).to eql config_options[:project_name] }
        it { expect(config.project_slug).to eql config_options[:project_slug] }
        it { expect(config.project_branch).to eql config_options[:project_branch] }
        it { expect(config.site).to eql Gemnasium::Configuration::DEFAULT_CONFIG['site'] }
        it { expect(config.use_ssl).to eql Gemnasium::Configuration::DEFAULT_CONFIG['use_ssl'] }
        it { expect(config.api_version).to eql Gemnasium::Configuration::DEFAULT_CONFIG['api_version'] }
        it { expect(config.ignored_paths).to include Regexp.new("^spec/") }
        it { expect(config.ignored_paths).to include Regexp.new("^tmp/[^/]+\\.lock") }
        it { expect(config.ignored_paths).to include Regexp.new("^[^\/]+\\.gemspec") }
      end
    end
  end

  pending "writable?"

  describe "#store_value!" do
    context "with a new value for an existing key" do
      let(:key) { :project_name }
      let(:value) { 'new-name' }

      # HACK: fake config reload
      let(:new_config) { Gemnasium::Configuration.new File.expand_path(config_file_path) }

      before do
        write_config_file
        config.store_value! key, value, "my project name"
      end

      it "updates the given key-value pair" do
        expect(new_config.project_name).to eql 'new-name'
      end

      it "keeps other key-value pairs unchanged" do
        expect(new_config.api_key).to eql config_options[:api_key]
        expect(new_config.project_branch).to eql config_options[:project_branch]
      end

      it "stores the given comment" do
        content = File.read File.expand_path(config_file_path)
        expect(content).to match /:project_name:.*# my project name/
      end
    end
  end

  describe "#migrate!" do
    before { write_config_file }
    subject { config.needs_to_migrate? }

    context "with NO profile_name key" do
      let(:config_options) do
        {
          api_key: 'api_key',
          project_name: 'gemnasium-gem',
          project_branch: 'master'
          # no profile_name
        }
      end

      it { should be false }
    end

    context "with profile_name key" do
      let(:config_options) do
        {
          project_name: 'gemnasium-gem',
          profile_name: 'tech-angels',
          api_key: '1337'
        }
      end

      it { should be true }
    end
  end

  describe "#migrate!" do
    before { write_config_file }

    let(:config_options) do
      {
        project_name: 'gemnasium-gem',
        profile_name: 'tech-angels',
        api_key: '1337'
      }
    end

    # HACK: fake config reload
    let(:new_config) { Gemnasium::Configuration.new File.expand_path(config_file_path) }

    it "removes the profile_name" do
      expect(config.profile_name).to eql 'tech-angels'
      config.migrate!
      expect(new_config.profile_name).to eql nil
    end

    it "preserves the other keys" do
      config.migrate!
      expect(new_config.project_name).to eql 'gemnasium-gem'
      expect(new_config.api_key).to eql '1337'
    end
  end
end
