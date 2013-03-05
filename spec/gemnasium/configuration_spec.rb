require 'fileutils'
require 'spec_helper'

describe Gemnasium::Configuration do
  describe 'default config' do
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG[:site]).to eql 'gemnasium.com' }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG[:use_ssl]).to eql true }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG[:api_version]).to eql 'v1' }
    it { expect(Gemnasium::Configuration::DEFAULT_CONFIG[:project_visibility]).to eql 'public' }
  end

  describe 'initialize' do
    let(:config_file_path) { 'tmp/config.yml' }

    context 'for an inexistant config file' do
      it { expect { Gemnasium::Configuration.new File.expand_path(config_file_path) }.to raise_error Errno::ENOENT }
    end

    context 'for a config file that does exist' do
      before { FileUtils.touch(config_file_path) }
      after { File.delete(config_file_path) }

      context 'with missing mandatory values' do
        let(:config_options) {{ profile_name: 'tech-angels', project_name: 'gemnasium-gem' }}
        before do
          File.open(config_file_path, 'w+') { |f| f.write(config_options.to_yaml) }
        end

          it { expect { Gemnasium::Configuration.new File.expand_path(config_file_path) }.to raise_error('Your configuration file does not contain all mandatory parameters or contain invalid values. Please check the documentation.') }
      end

      context 'with all mandatory values' do
        let(:config_options) {{ api_key: 'api_key', profile_name: 'tech-angels', project_name: 'gemnasium-gem', project_branch: 'master' }}
        before do
          File.open(config_file_path, 'w+') { |f| f.write(config_options.to_yaml) }
        end
        let(:config) { Gemnasium::Configuration.new File.expand_path(config_file_path) }

        it { expect(config.api_key).to eql config_options[:api_key] }
        it { expect(config.profile_name).to eql config_options[:profile_name] }
        it { expect(config.project_name).to eql config_options[:project_name] }
        it { expect(config.project_branch).to eql config_options[:project_branch] }
        it { expect(config.site).to eql Gemnasium::Configuration::DEFAULT_CONFIG[:site] }
        it { expect(config.use_ssl).to eql Gemnasium::Configuration::DEFAULT_CONFIG[:use_ssl] }
        it { expect(config.api_version).to eql Gemnasium::Configuration::DEFAULT_CONFIG[:api_version] }
        it { expect(config.project_visibility).to eql Gemnasium::Configuration::DEFAULT_CONFIG[:project_visibility] }
      end
    end
  end
end