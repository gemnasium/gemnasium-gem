# 3.2.1 / 2014-11-27

* Add deprecation warning

# 3.2.0 / 2014-06-26

* [#15][] Add --silence-branch option to the 'push' command

* [#15][] Add --silence-branch option to the 'push' command

# 3.1.0 / 2014-06-03

* [#10][] Add --ignore-branch option to the 'push' command
* Parse ERB code in the configuration file

# 3.0.1 / 2014-02-11

* Add support for Python and PHP Composer dependency files

# 3.0.0 / 2014-02-10

**API V2 is now deprecated and all previous gem releases have been yanked**

* Update config file syntax: replace `profile_name` with `project_slug`
* Add `migrate` command to migrate the config file from previous versions
* Add `resolve` command to find a project that matches a name and a branch
* Make it compatible with Gemnasium API v3

# 2.0.2 / 2013-07-31

* [#6][] Fix spec for fedora packaging (@ktdreyer)

# 2.0.1 / 2013-07-25

* Update regexp to fetch dependency files in subrepositories.

# 2.0.0 / 2013-04-30

**API V1 is now deprecated and all previous gem releases have been yanked**

* Drop `project_visibility` option, all offline projects are private now
* Add `ignored_paths` options to avoid pushing useless files

# 1.0.1 / 2013-04-02

* Fix Git after-commit hook (drop Perl style regexp) (revealed by @veilleperso)
* Fix Gem's description

# 1.0.0 / 2013-03-05

Initial release

