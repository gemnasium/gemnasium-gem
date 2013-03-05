# Gemnasium gem
[![Dependency Status](https://gemnasium.com/gemnasium/gemnasium-gem.png)](https://gemnasium.com/gemnasium/gemnasium-gem)
[![Build Status](https://travis-ci.org/gemnasium/gemnasium-gem.png?branch=master)](https://travis-ci.org/gemnasium/gemnasium-gem)

This gem lets you push your dependency files to [Gemnasium](https://gemnasium.com/) to track your project's dependencies and get notified about updates and security advisories.

Gemnasium app offers Github integration with fully automated synchronization but you can use this gem if you don't want to authorize access to your repositories (ie: for privacy concern).

Supported dependency files are:

* Gemfile
* Gemfile.lock
* *.gemspec
* package.json
* npm-shrinkwrap.json

## Installation

Add this line to your application's Gemfile:

    gem 'gemnasium'

Or in your terminal:

    $ gem install gemnasium

Add configuration file in your project

    $ gemnasium install

Install command supports 2 options : `--rake` and `--git` to respectively install the gemnasium [rake task](#2-via-the-rake-task) and a [post-commit git hook](#3-via-the-post-commit-git-hook).

`gemnasium install` will add the config/gemnasium.yml file to your .gitignore so your private API key won't be committed. If you use another versionning system, please remember to ignore this file, especially for public project. 

__Warning: your api key is dedicated to your own user account and must not be published!__

Fill the values of the new config/gemnasium.yml file.

## Usage

There is multiple ways to use the gemnasium gem. You can choose whichever you prefer.

### 1. Via the command line

Using gemnasium from the command line is as simple as typing `gemnasium [command]` :

__To create a project on Gemnasium:__

    $ gemnasium create

Create command will look for data in your config/gemnasium.yml configuration file to create a project.
If your project was previously managed automatically from Github or if you want to change the visibility of an existing project, you can use the `--force` option to overwrite existing setup.

Please note that automatic Github synchronization will be dropped once project is configured with this gem.

__To push your dependency files on Gemnasium:__

    $ gemnasium push

### 2. Via the rake task

Gemnasium gem comes with a rake task ready to be used. To use it, you need to install it via: `gemnasium install --rake`
Once installed, you'll have access to 2 tasks:

__To create a project on Gemnasium:__

    $ rake gemnasium:create

Create command will look for data in your config/gemnasium.yml configuration file to create a project.
If your project was previously managed automatically from Github or if you want to change the visibility of an existing project, you can use the `gemnasium:create:force` subtask to overwrite existing setup.

Please note that automatic Github synchronization will be dropped once project is configured with this gem.

__To push your dependency files on Gemnasium:__

    $ rake gemnasium:push

### 3. Via the post-commit git hook

We wrote for you a ready-to-use [post-commit git hook](lib/templates/post-commit).

Once installed via `gemnasium install --git`, the gem will push your dependency files after each commit only if they have changed.

### 4. Directly in your code

If you need to use Gemnasium gem right into your code, you can do so just like below:

```ruby
require 'gemnasium'


# To install gemnasium files
#
# options is a Hash which can contain the following keys:
#   project_path (required) - [String] path to the project
#   install_rake_task       - [Boolean] whether or not to install the rake task
#   install_git_hook        - [Boolean] whether or not to install the git hook
Gemnasium.install(options)

# To create your project on gemnasium
#
# options is a Hash which can contain the following keys:
#   project_path (required) - [String] path to the project
#   overwrite_attr          - [Boolean] whether or not to overwrite existing project's attributes
Gemnasium.create_project(options)

# To push supported dependency files to gemnasium
#
# options is a Hash which can contain the following keys:
#   project_path (required) - [String] path to the project
Gemnasium.push(options)
```

## Sample config

Here is a sample config file for our public project **tech-angels/vandamme** available at https://gemnasium.com/tech-angels/vandamme

```yaml
api_key: "some_secret_api_key"
profile_name: "tech-angels"
project_name: "vandamme"   
project_visibility: "public"
project_branch: "master"
```

## Troubleshooting

Gemnasium will try to display the most accurate error message when something goes wrong. 

Though, if you're stil stuck with something, feel free to contact [Gemnasium support](https://gemnasium.freshdesk.com).

## Contributing

1. Fork the project.
2. Make your feature or bug fix.
3. Test it.
4. Commit.
5. Create new pull request.

## Credits

[![Tech-Angels](http://media.tumblr.com/tumblr_m5ay3bQiER1qa44ov.png)](http://www.tech-angels.com)
