Feature: Create or update a project on Gemnasium

  By using gemnasium install [options], the user is able to install
  the necessary files to run gemnasium.

  Scenario: Without option for a clean repo
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    When I run `gemnasium install`
    Then it should create the config directory
    And it should create the config file
    And the exit status should be 0

  Scenario: Without option for a repo with a config directory
    Given a directory named "project/foo/bar/config"
    And I cd to "project/foo/bar"
    When I run `gemnasium install`
    Then it should create the config file
    And the exit status should be 0

  Scenario: Without option for a repo with the config file already installed
    Given an empty file named "project/foo/bar/config/gemnasium.yml"
    And I cd to "project/foo/bar"
    When I run `gemnasium install`
    Then the output should match:
      """
      The file .+\/config\/gemnasium.yml already exists
      """
    And the exit status should be 0

  Scenario: With git option for a non git repo
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    When I run `gemnasium install --git`
    Then it should create the config directory
    And it should create the config file
    And the output should match:
      """
      .*\/project\/foo\/bar is not a git repository\. Try to run `git init`\.
      """
    And the file ".git/hooks/post-commit" should not exist
    And the exit status should be 0

  Scenario: With git option for git repo without post-commit hook
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    And I run `git init`
    When I run `gemnasium install --git`
    Then it should create the config directory
    And it should create the config file
    And it should create the post-commit hook
    And the exit status should be 0

  Scenario: With git option for git repo with a post-commit hook file
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    And I run `git init`
    And an empty file named ".git/hooks/post-commit"
    When I run `gemnasium install --git`
    Then it should create the config directory
    And it should create the config file
    And the output should match:
      """
      The file .+\/.git\/hooks\/post-commit already exists
      """
    And the exit status should be 0

  Scenario: With rake option for a repo without Rakefile
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    When I run `gemnasium install --rake`
    Then it should create the config directory
    And it should create the config file
    And the output should contain "Rakefile not found."
    And the file "lib/tasks/gemnasium.rake" should not exist
    And the exit status should be 0

  Scenario: With rake option for a repo with a Rakefile without lib/tasks directory
    Given an empty file named "project/foo/bar/Rakefile"
    And I cd to "project/foo/bar"
    When I run `gemnasium install --rake`
    Then it should create the config directory
    And it should create the config file
    And it should create the tasks directory
    And it should create the task file
    And the exit status should be 0

  Scenario: With rake option for a repo with a Rakefile with a lib/tasks directory
    Given an empty file named "project/foo/bar/Rakefile"
    And a directory named "project/foo/bar/lib/tasks"
    And I cd to "project/foo/bar"
    When I run `gemnasium install --rake`
    Then it should create the config directory
    And it should create the config file
    And it should create the task file
    And the exit status should be 0

  Scenario: With rake option for a repo with the rake tasks already installed
    Given an empty file named "project/foo/bar/Rakefile"
    And an empty file named "project/foo/bar/lib/tasks/gemnasium.rake"
    And I cd to "project/foo/bar"
    When I run `gemnasium install --rake`
    Then it should create the config directory
    And it should create the config file
    And the output should match:
      """
      The file .+\/lib\/tasks\/gemnasium\.rake already exists
      """
    And the exit status should be 0

  Scenario: With both rake and git options
    Given an empty file named "project/foo/bar/Rakefile"
    And I cd to "project/foo/bar"
    And I run `git init`
    When I run `gemnasium install --git --rake`
    Then it should create the config directory
    And it should create the config file
    And it should create the task file
    And it should create the post-commit hook