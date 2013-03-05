Feature: Create or update a project on Gemnasium

  By using gemnasium create [options], the user is able to create a new
  project on Gemnasium or to update an existing one.

  Scenario Outline: Without configuration file
    Given a directory named "project/foo/bar"
    And I cd to "project/foo/bar"
    When I run `gemnasium create`
    Then the output should contain "/config/gemnasium.yml) does not exist."
    And the output should contain "Please run `gemnasium install`."
    And the exit status should be 1