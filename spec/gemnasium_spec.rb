require 'spec_helper'

shared_examples_for 'an installed file' do
  it 'creates the configuration file' do
    expect(File.exists? target_path).to be_true
    # Test that the files are identical comparing their MD5 hashes
    template_file_md5 = Digest::MD5.hexdigest(File.read(template_path))
    new_file_md5 = Digest::MD5.hexdigest(File.read(target_path))
    expect(new_file_md5).to eql template_file_md5
  end

  it 'informs the user that the file has been created' do
    expect(output).to include "File created in #{target_path}."
  end
end

describe Gemnasium do
  let(:output) { [] }
  let(:error_output) { [] }
  let(:project_path) { File.expand_path("#{File.dirname(__FILE__)}../../tmp") }
  before do
    Gemnasium.stub(:notify) { |arg| output << arg }
    Gemnasium.stub(:quit_because_of) { |arg| error_output << arg && abort }
    stub_config
    stub_requests
  end

  describe 'push' do
    context 'on a non tracked branch' do
      before { Gemnasium.stub(:current_branch).and_return('non_project_branch') }

      it 'quit the program' do
        expect{ Gemnasium.push({ project_path: project_path }) }.to raise_error { |e|
          expect(e).to be_kind_of SystemExit
          expect(error_output).to include "Gemnasium : Dependency files updated but not on tracked branch (master), ignoring...\n"
        }
      end
    end

    context 'on the tracked branch' do
      before { Gemnasium.stub(:current_branch).and_return('master') }

      context 'with no supported dependency files found' do
        before { Gemnasium::DependencyFiles.stub(:get_sha1s_hash).and_return([]) }

        it 'quit the program with an error' do
          expect{ Gemnasium.push({ project_path: project_path }) }.to raise_error { |e|
            expect(e).to be_kind_of SystemExit
            expect(error_output).to include "No supported dependency files detected."
          }
        end
      end

      context 'with supported dependency files found' do
        let(:sha1_hash) {{ 'new_gemspec.gemspec' => 'gemspec_sha1_hash', 'modified_lockfile.lock' => 'lockfile_sha1_hash', 'Gemfile_unchanged.lock' => 'gemfile_sha1_hash' }}
        before { Gemnasium::DependencyFiles.stub(:get_sha1s_hash).and_return(sha1_hash) }

        context 'for a gemnasium project already up-to-date' do
          before do
            stub_config({ project_name: 'up_to_date_project' })
            Gemnasium.push({ project_path: project_path })
          end

          it 'quit the program with an error' do
            expect(output).to include "The project's dependency files are up-to-date."
          end
        end

        context 'for gemnasium project not up-to-date' do
          let(:hash_to_upload) {[{ filename: 'new_gemspec.gemspec', sha: 'gemspec_sha1_hash', content: 'stubbed gemspec content' },
                                { filename: 'modified_lockfile.lock', sha: 'lockfile_sha1_hash', content: 'stubbed lockfile content' }]}
          before do
            Gemnasium::DependencyFiles.stub(:get_content_to_upload).and_return(hash_to_upload)
            Gemnasium.push({ project_path: project_path })
          end

          it 'informs the user that it found supported dependency files' do
            expect(output).to include "#{sha1_hash.keys.count} supported dependency file(s) found: #{sha1_hash.keys.join(', ')}"
          end

          it 'makes a request to Gemnasium to get updated files to upload' do
            expect(WebMock).to have_requested(:post, api_url('/api/v2/profiles/tech-angels/projects/gemnasium-gem/dependency_files/compare'))
                    .with(:body => sha1_hash.to_json,
                          :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
          end

          it 'informs the user that Gemnasium has deleted an old dependency file' do
            expect(output).to include "1 deleted file(s): old_dependency_file"
          end

          it 'displays the list of files that are being uploaded' do
            expect(output).to include "2 file(s) to upload: new_gemspec.gemspec, modified_lockfile.lock"
          end

          it 'makes a request to Gemnasium to upload needed files' do
            expect(WebMock).to have_requested(:post, api_url('/api/v2/profiles/tech-angels/projects/gemnasium-gem/dependency_files/upload'))
                    .with(:body => hash_to_upload.to_json,
                          :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
          end

          it 'informs the user of added file' do
            expect(output).to include 'Added dependency files: ["new_gemspec.gemspec"]'
          end

          it 'informs the user of updated file' do
            expect(output).to include 'Updated dependency files: ["modified_lockfile.lockfile"]'
          end

          it 'informs the user of unchanged file' do
            expect(output).to_not include 'Unchanged dependency files: []'
          end

          it 'informs the user of unsupported file' do
            expect(output).to_not include 'Unsupported dependency files: []'
          end
        end
      end
    end
  end

  describe 'create_project' do
    context 'for an already existing project' do
      before { stub_config({ project_name: 'existing_project' }) }

      context 'without overwrite option' do
        it 'quit the program with an error' do
          expect{ Gemnasium.create_project({ project_path: project_path }) }.to raise_error { |e|
            expect(e).to be_kind_of SystemExit
            expect(error_output).to include "The project `#{Gemnasium.config.project_name}` already exists for the profile `#{Gemnasium.config.profile_name}`."
          }
        end
      end

      context 'with overwrite option' do
        before { Gemnasium.create_project({ project_path: project_path, overwrite_attr: true }) }

        it 'issues the correct request' do
          expect(WebMock).to have_requested(:post, api_url("/api/v2/profiles/tech-angels/projects"))
              .with(:body => {name: "existing_project", branch: "master", overwrite_attributes: true},
                    :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
        end

        it 'displays a confirmation message' do
          expect(output).to include 'Project `existing_project` successfully created for tech-angels.'
          expect(output).to include 'Remaining private slots for this profile: 9001'
        end
      end
    end

    context 'for an inexistant project' do
      before { Gemnasium.create_project({ project_path: project_path }) }

      it 'issues the correct request' do
        expect(WebMock).to have_requested(:post, api_url("/api/v2/profiles/tech-angels/projects"))
            .with(:body => {name: "gemnasium-gem", branch: "master"},
                  :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
      end

      it 'displays a confirmation message' do
        expect(output).to include 'Project `gemnasium-gemn` successfully created for tech-angels.'
        expect(output).to include 'Remaining private slots for this profile: 9001'
      end
    end
  end

  describe 'install' do
    after { FileUtils.rm_r "#{project_path}/config" }

    context 'if config file already exists' do
      before do
        FileUtils.mkdir_p "#{project_path}/config"
        FileUtils.touch("#{project_path}/config/gemnasium.yml")

        Gemnasium.install({ project_path: project_path })
      end

      it 'informs the user that the file already exists' do
        expect(output).to include "The file #{project_path}/config/gemnasium.yml already exists"
      end
    end

    context 'if config file does not exist' do
      context 'neither do the config folder' do
        before do
          FileUtils.touch "#{project_path}/.gitignore"
          Gemnasium.install({ project_path: project_path })
        end
        after { FileUtils.rm "#{project_path}/.gitignore" }

        it 'creates the config folder' do
          expect(File.exists? "#{project_path}/config").to be_true
        end

        it 'informs the user that the folder has been created' do
          expect(output).to include "Creating config directory"
        end

        it_should_behave_like 'an installed file' do
          let(:template_path) { File.expand_path("#{File.dirname(__FILE__)}../../lib/templates/gemnasium.yml") }
          let(:target_path) { "#{project_path}/config/gemnasium.yml" }
        end

        it 'adds the config file to the .gitignore' do
          expect(output).to include "Configuration file added to your project's .gitignore."
          expect(File.open("#{project_path}/.gitignore").read()).to include "# Gemnasium gem configuration file\nconfig/gemnasium.yml"
        end

        it 'asks the user to fill the config file' do
          expect(output).to include 'Please fill configuration file with accurate values.'
        end
      end

      context 'with an already existing config folder' do
        before do
          FileUtils.mkdir_p "#{project_path}/config"
          Gemnasium.install({ project_path: project_path })
        end

        it 'does not inform the user that the config folder has been created' do
          expect(output).to_not include "Creating config directory"
        end

        it_should_behave_like 'an installed file' do
          let(:template_path) { File.expand_path("#{File.dirname(__FILE__)}../../lib/templates/gemnasium.yml") }
          let(:target_path) { "#{project_path}/config/gemnasium.yml" }
        end

        it 'asks the user to fill the config file' do
          expect(output).to include 'Please fill configuration file with accurate values.'
        end
      end
    end

    context 'with git option' do
      context 'for a non git repo' do
        before { Gemnasium.install({ project_path: project_path, install_git_hook: true }) }

        it 'informs the user that the target project is not a git repository' do
          expect(output).to include "#{project_path} is not a git repository. Try to run `git init`."
        end

        it 'does not install the hook' do
          expect(File.exists? "#{project_path}/.git/hooks/post-commit").to eql false
        end
      end

      context 'for a git repo' do
        before { FileUtils.mkdir_p "#{project_path}/.git/hooks" }
        after { FileUtils.rm_r "#{project_path}/.git" }

        context 'if the hook already exists' do
          before do
            FileUtils.touch("#{project_path}/.git/hooks/post-commit")
            Gemnasium.install({ project_path: project_path, install_git_hook: true })
          end

          it 'informs the user that a post-commit hook already exists.' do
            expect(output).to include "The file #{project_path}/.git/hooks/post-commit already exists"
          end
        end

        context 'if the hook does not exist' do
          before { Gemnasium.install({ project_path: project_path, install_git_hook: true }) }

          it_should_behave_like 'an installed file' do
            let(:template_path) { File.expand_path("#{File.dirname(__FILE__)}../../lib/templates/post-commit") }
            let(:target_path) { "#{project_path}/.git/hooks/post-commit" }
          end
        end
      end
    end

    context 'with rake option' do
      context 'for a repo without Rakefile' do
        before { Gemnasium.install({ project_path: project_path, install_rake_task: true }) }

        it 'informs the user that the target repo does not contain Rakefile' do
          expect(output).to include "Rakefile not found."
        end

        it 'does not install the task' do
          expect(File.exists? "#{project_path}/lib/tasks/gemnasium.rake").to eql false
        end
      end

      context 'for a project with Rakefile' do
        before { FileUtils.touch("#{project_path}/Rakefile") }
        after do
          FileUtils.rm "#{project_path}/Rakefile"
          FileUtils.rm_r "#{project_path}/lib"
        end

        context 'without /lib/tasks foler' do
          before { Gemnasium.install({ project_path: project_path, install_rake_task: true }) }

          it 'creates the /lib/tasks folder' do
            expect(File.exists? "#{project_path}/lib/tasks").to be_true
          end

          it 'informs the user that the folder has been created' do
            expect(output).to include "Creating lib/tasks directory"
          end

          it_should_behave_like 'an installed file' do
            let(:template_path) { File.expand_path("#{File.dirname(__FILE__)}../../lib/templates/gemnasium.rake") }
            let(:target_path) { "#{project_path}/lib/tasks/gemnasium.rake" }
          end

          it 'informs the user on how to use the rake tasks' do
            expect(output).to include 'Usage:'
            expect(output).to include "\trake gemnasium:push \t\t- to push your dependency files"
            expect(output).to include "\trake gemnasium:create \t\t- to create your project on Gemnasium"
            expect(output).to include "\trake gemnasium:create:force - to overwrite already existing Gemnasium project attributes"
          end
        end

        context 'with existing /lib/tasks foler' do
          before { FileUtils.mkdir_p "#{project_path}/lib/tasks" }

          context 'if the task file already exists' do
            before do
              FileUtils.touch("#{project_path}/lib/tasks/gemnasium.rake")
              Gemnasium.install({ project_path: project_path, install_rake_task: true })
            end

            it 'informs the user that the rake task already exists.' do
              expect(output).to include "The file #{project_path}/lib/tasks/gemnasium.rake already exists"
            end
          end

          context 'if the task file does not exist' do
            before { Gemnasium.install({ project_path: project_path, install_rake_task: true }) }

            it_should_behave_like 'an installed file' do
              let(:template_path) { File.expand_path("#{File.dirname(__FILE__)}../../lib/templates/gemnasium.rake") }
              let(:target_path) { "#{project_path}/lib/tasks/gemnasium.rake" }
            end

            it 'informs the user on how to use the rake tasks' do
              expect(output).to include 'Usage:'
              expect(output).to include "\trake gemnasium:push \t\t- to push your dependency files"
              expect(output).to include "\trake gemnasium:create \t\t- to create your project on Gemnasium"
              expect(output).to include "\trake gemnasium:create:force - to overwrite already existing Gemnasium project attributes"
            end
          end
        end
      end
    end
  end
end