def api_url(path)
  config = Gemnasium.config
  protocol = config.use_ssl ? "https://" : "http://"

  "#{protocol}X:#{config.api_key}@#{config.site}#{path}"
end

def stub_config(options = {})
  stubbed_config = double("Gemnasium::Configuration")
  stubbed_config.stub(:site).and_return('gemnasium.com')
  stubbed_config.stub(:use_ssl).and_return(true)
  stubbed_config.stub(:api_key).and_return('test_api_key')
  stubbed_config.stub(:api_version).and_return('v3')
  stubbed_config.stub(:project_name).and_return(options[:project_name] || 'gemnasium-gem')
  stubbed_config.stub(:project_slug).and_return(options[:project_slug] || 'existing-slug')
  stubbed_config.stub(:project_branch).and_return('master')

  Gemnasium.stub(:config).and_return(stubbed_config)
  Gemnasium.stub(:load_config).and_return(stubbed_config)
end

def stub_requests
  config = Gemnasium.config
  request_headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
  response_headers = {'Content-Type'=>'application/json'}

  # Push requests
  stub_request(:post, api_url("/api/#{config.api_version}/projects/up_to_date_project/dependency_files/compare"))
           .with(:headers => request_headers)
           .to_return(:status => 200,
                      :body => '{ "to_upload": [], "deleted": [] }',
                      :headers => response_headers)

  stub_request(:post, api_url("/api/#{config.api_version}/projects/existing-slug/dependency_files/compare"))
           .with(:body => '{"new_gemspec.gemspec":"gemspec_sha1_hash","modified_lockfile.lock":"lockfile_sha1_hash","Gemfile_unchanged.lock":"gemfile_sha1_hash"}',
                 :headers => request_headers)
           .to_return(:status => 200,
                      :body => '{ "to_upload": ["new_gemspec.gemspec", "modified_lockfile.lock"], "deleted": ["old_dependency_file"] }',
                      :headers => response_headers)

  stub_request(:post, api_url("/api/#{config.api_version}/projects/existing-slug/dependency_files/upload"))
           .with(:body => '[{"filename":"new_gemspec.gemspec","sha":"gemspec_sha1_hash","content":"stubbed gemspec content"},{"filename":"modified_lockfile.lock","sha":"lockfile_sha1_hash","content":"stubbed lockfile content"}]',
                 :headers => request_headers)
           .to_return(:status => 200,
                      :body => '{ "added": ["new_gemspec.gemspec"], "updated": ["modified_lockfile.lockfile"], "unchanged": [], "unsupported": [] }',
                      :headers => response_headers)

  # Create requests
  stub_request(:post, api_url("/api/#{config.api_version}/projects"))
          .with(:body => '{"name":"gemnasium-gem","branch":"master"}',
                :headers => request_headers)
          .to_return(:status => 200,
                     # FIXME: make sure the response body is consistent with API v3
                     :body => '{ "name": "gemnasium-gem", "slug": "new-slug", "remaining_slot_count": 9001 }',
                     :headers => response_headers)

  # Connection model's test requests
  stub_request(:get, api_url('/test_path'))
          .with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})

  stub_request(:post, api_url('/test_path'))
          .with(:body => {"foo"=>"bar"}, :headers => request_headers)
end
