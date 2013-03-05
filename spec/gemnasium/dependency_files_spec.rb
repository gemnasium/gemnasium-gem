require 'spec_helper'

describe Gemnasium::DependencyFiles do
  let(:project_path) { File.expand_path("#{File.dirname(__FILE__)}../../../")}

  describe 'get_sha1s_hash' do
    context 'with a non matching regexp' do
      it 'returns an empty Hash' do
        sha1s_hash = Gemnasium::DependencyFiles.get_sha1s_hash("#{project_path}/tmp")

        expect(sha1s_hash).to be_kind_of Hash
        expect(sha1s_hash).to be_empty
      end
    end

    context 'with a mathing regexp' do
      it 'returns a Hash of matching files and their git calculated hash' do
        sha1s_hash = Gemnasium::DependencyFiles.get_sha1s_hash(project_path)

        expect(sha1s_hash).to include({ 'gemnasium.gemspec' => git_hash('gemnasium.gemspec') })
      end
    end
  end

  describe 'get_content_to_upload' do
    context 'with no files' do
      it 'returns an empty Hash' do
        content_to_upload = Gemnasium::DependencyFiles.get_content_to_upload(project_path, [])

        expect(content_to_upload).to be_kind_of Array
        expect(content_to_upload).to be_empty
      end
    end

    context 'with a mathing regexp' do
      it 'returns a Hash of matching files and their git calculated hash' do
        content_to_upload = Gemnasium::DependencyFiles.get_content_to_upload(project_path, ['gemnasium.gemspec'])

        expect(content_to_upload).to eql([{ filename: 'gemnasium.gemspec', sha: git_hash('gemnasium.gemspec'), content: File.open('gemnasium.gemspec') {|io| io.read} }])
      end
    end
  end
end

def git_hash(path)
  %x( git hash-object #{path} ).strip
end