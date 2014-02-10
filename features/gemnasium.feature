Feature: Help messages about gemnasium gem

  By using gemnasium [options], the user is able to get helpfull messages
  about how to use the gemnasium gem.

  Scenario: Without options
    When I run `gemnasium`
    Then the output should contain "Please see `gemnasium --help` for valid options"
    And the exit status should be 0

  Scenario: With invalid option
    When I run `gemnasium -z`
    Then the output should contain exactly:
      """
      Invalid option: -z
      Please see `gemnasium --help` for valid options\n
      """
    And the exit status should be 1

  Scenario Outline: With version option
    When I run `gemnasium <option>`
    Then the output should contain exactly:
      """
      gemnasium v2.0.1\n
      """
    And the exit status should be 0

    Scenarios: Version options
      | option    |
      | -v        |
      | --version |

  Scenario Outline: With version option
    When I run `gemnasium <option>`
    Then the output should contain exactly:
      """
      Usage: gemnasium [options]
          -v, --version                    Show Gemnasium version
          -h, --help                       Display this message

      Available commands are:
        create   :   Create or update project on Gemnasium
        install  :   Install the necessary config file
        push     :   Push your dependency files to Gemnasium
        migrate  :   Migrate the configuration file
        resolve  :   Resolve project name to an existing project on Gemnasium

      See `gemnasium COMMAND --help` for more information on a specific command.\n
      """
    And the exit status should be 0

    Scenarios: Version options
      | option  |
      | -h      |
      | --help  |
