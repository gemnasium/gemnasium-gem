require 'digest/sha1'

module Gemnasium
  class DependencyFiles

    SUPPORTED_DEPENDENCY_FILES = /^(Gemfile|Gemfile\.lock|.*\.gemspec|package\.json|npm-shrinkwrap\.json)$/

    # Get a Hash of sha1s for each file corresponding to the regex
    #
    # @param regexp [Regexp] the regular expression of requested files
    # @return [Hash] the hash associating each file path with its SHA1 hash
    def self.get_sha1s_hash(project_path)
      Dir.chdir(project_path)
      Dir.glob("**/**").grep(SUPPORTED_DEPENDENCY_FILES).inject({}) do |h, file_path|
        h[file_path] = calculate_sha1("#{project_path}/#{file_path}")
        h
      end
    end

    # Get the content to upload to Gemnasium.
    #
    # @param files_path [Array] an array containing the path of the files
    # @return [Array] array of hashes containing file name, file sha and file content
    def self.get_content_to_upload(project_path, files_path)
      files_path.inject([]) do |arr, file_path|
        arr << { filename: file_path, sha: calculate_sha1(file_path), content: File.open("#{project_path}/#{file_path}") {|io| io.read} }
      end
    end

    private

    # Calculate hash of a file in the same way git does
    #
    # @param file_path [String] path of the file 
    # @return [String] SHA1 of the file
    def self.calculate_sha1(file_path)
      mem_buf = File.open(file_path) {|io| io.read}
      size = mem_buf.size
      header = "blob #{size}\0" # type[space]size[null byte]

      Digest::SHA1.hexdigest(header + mem_buf)
    end
  end
end