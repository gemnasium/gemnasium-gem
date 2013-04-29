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
  stubbed_config.stub(:api_version).and_return('v2')
  stubbed_config.stub(:profile_name).and_return('tech-angels')
  stubbed_config.stub(:project_name).and_return(options[:project_name] || 'gemnasium-gem')
  stubbed_config.stub(:project_branch).and_return('master')

  Gemnasium.stub(:config).and_return(stubbed_config)
  Gemnasium.stub(:load_config).and_return(stubbed_config)
end

def stub_requests
  config = Gemnasium.config
  # Push requests
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects/up_to_date_project/dependency_files/compare"))
           .with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
           .to_return(:status => 200,
                      :body => '{ "to_upload": [], "deleted": [] }',
                      :headers => {'Content-Type'=>'application/json'})
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects/gemnasium-gem/dependency_files/compare"))
           .with(:body => '{"new_gemspec.gemspec":"gemspec_sha1_hash","modified_lockfile.lock":"lockfile_sha1_hash","Gemfile_unchanged.lock":"gemfile_sha1_hash"}',
                 :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
           .to_return(:status => 200,
                      :body => '{ "to_upload": ["new_gemspec.gemspec", "modified_lockfile.lock"], "deleted": ["old_dependency_file"] }',
                      :headers => {'Content-Type'=>'application/json'})
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects/gemnasium-gem/dependency_files/upload"))
           .with(:body => '[{"filename":"new_gemspec.gemspec","sha":"gemspec_sha1_hash","content":"stubbed gemspec content"},{"filename":"modified_lockfile.lock","sha":"lockfile_sha1_hash","content":"stubbed lockfile content"}]',
                 :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
           .to_return(:status => 200,
                      :body => '{ "added": ["new_gemspec.gemspec"], "updated": ["modified_lockfile.lockfile"], "unchanged": [], "unsupported": [] }',
                      :headers => {})
  # Create requests
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects"))
          .with(:body => '{"name":"gemnasium-gem","branch":"master"}',
                :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
          .to_return(:status => 200,
                     :body => "{ \"name\": \"gemnasium-gemn\", \"profile\": \"#{config.profile_name}\", \"remaining_slot\": 9001 }",
                     :headers => {'Content-Type'=>'application/json'})
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects"))
          .with(:body => '{"name":"existing_project","branch":"master"}',
                :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
          .to_return do |request|
            request_body = JSON.parse(request.body)
            {
              :status   => 422,
              :body     => { error: 'project_already_exists', message: "The project `#{request_body['name']}` already exists for the profile `#{config.profile_name}`." }.to_json,
              :headers  => { 'Content-Type'=>'application/json' }
            }
          end
  stub_request(:post, api_url("/api/#{config.api_version}/profiles/#{config.profile_name}/projects"))
          .with(:body => '{"name":"existing_project","branch":"master","overwrite_attributes":true}',
                :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
          .to_return(:status => 200,
                     :body => "{ \"name\": \"existing_project\", \"profile\": \"#{config.profile_name}\", \"remaining_slot\": 9001 }",
                     :headers => {'Content-Type'=>'application/json'})

  # Connection model's test requests
  stub_request(:get, api_url('/test_path'))
          .with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
  stub_request(:post, api_url('/test_path'))
          .with(:body => {"foo"=>"bar"}, :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
end