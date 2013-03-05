require 'aruba/cucumber'
require 'fileutils'

After do
  test_project_path = "#{File.dirname(__FILE__)}../../../tmp/aruba/project"
  FileUtils.rm_r File.expand_path(test_project_path) if File.exists? test_project_path
end