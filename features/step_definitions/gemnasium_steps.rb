Then /^it should create the config directory$/ do
  steps %{
    Then the output should match:
      """
      Creating config directory
      """
    And a directory named "config" should exist
  }
end
Then /^it should create the config file$/ do
  steps %{
    Then the output should match:
      """
      File created in .*\/config\/gemnasium\.yml\.
      Please fill configuration file with accurate values\.
      """
    And a file named "config/gemnasium.yml" should exist
  }
end
Then /^it should create the post-commit hook$/ do
  steps %{
    Then the output should match:
      """
      File created in .*\/.git\/hooks\/post-commit\.
      """
    And a file named ".git/hooks/post-commit" should exist
  }
end
Then /^it should create the task file$/ do
  steps %{
    Then the output should match:
      """
      File created in .*\/lib\/tasks\/gemnasium.rake.
      """
    And the output should contain:
      """
      Usage:
      	rake gemnasium:push 		- to push your dependency files
      	rake gemnasium:create 		- to create your project on Gemnasium
      """
    And a file named "lib/tasks/gemnasium.rake" should exist
  }
end
Then /^it should create the tasks directory$/ do
  steps %{
    Then the output should match:
      """
      Creating lib/tasks directory.
      """
    And a directory named "lib/tasks" should exist
  }
end
