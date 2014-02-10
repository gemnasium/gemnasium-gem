require 'spec_helper'

describe Gemnasium::Connection do
  before do
    stub_config
    stub_requests
  end
  let(:connection) { Gemnasium::Connection.new }

  describe 'initialize' do
    it 'initializes a Net::HTTP object' do
      connection.instance_variable_get('@connection').should be_kind_of(Net::HTTP)
    end
  end

  describe 'get' do
    before { connection.get('/test_path') }

    it 'issues a GET request' do
      expect(WebMock).to have_requested(:get, api_url('/test_path'))
                .with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
    end
  end

  describe 'post' do
    before { connection.post('/test_path', { foo: 'bar' }.to_json) }

    it 'issues a POST request' do
      expect(WebMock).to have_requested(:post, api_url('/test_path'))
                .with(:body => {"foo"=>"bar"}, :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
    end
  end

  describe 'api_path_for' do
    context 'base API path' do
      it{ expect(connection.api_path_for('base')).to eql "/api/#{Gemnasium.config.api_version}" }
    end

    context 'projects API path' do
      it{ expect(connection.api_path_for('projects')).to eql "/api/#{Gemnasium.config.api_version}/projects" }
    end

    context 'dependency files API path' do
      it{ expect(connection.api_path_for('dependency_files')).to eql "/api/#{Gemnasium.config.api_version}/projects/#{Gemnasium.config.project_slug}/dependency_files" }
    end
  end
end
