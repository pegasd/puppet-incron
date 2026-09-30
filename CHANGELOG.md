# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- FreeBSD support (14 and 15), including acceptance testing.
- AlmaLinux 9 and Rocky 9 support (incron is pulled from EPEL, which must be
  enabled beforehand; the module manages no repositories).
- New `root_group`, `conf_file`, `allow_file`, `deny_file`, `incrond_dir` and
  `spool_dir` parameters (FreeBSD keeps incron config under `/usr/local/etc` and
  uses the `wheel` group).

### Changed
- Switch acceptance testing from Beaker to Litmus.
- Switch CI from Travis CI to GitHub Actions.
- Require Puppet >= 8 (drop Puppet 4, 5 and 6).
- Relax `puppetlabs/stdlib` and `puppetlabs/concat` requirements to `< 11.0.0`.
- Update supported operating systems to Ubuntu 22.04/24.04, Debian 12,
  AlmaLinux 9, Rocky 9 and FreeBSD 14/15.

### Removed
- Drop support for EOL operating systems (CentOS 5/6/7, Debian 8/9, Fedora 30,
  RedHat 5/6/7, Ubuntu 14.04/16.04/18.04).

## [0.7.0] - 2019-09-18
### Added
- [GH-11](https://github.com/pegasd/puppet-incron/issues/11): Add `Debian`, `RedHat`, `Fedora`, and `CentOS` support:
    - Add data in modules so that incron service name is different under various distributions
    - Add acceptance testing for `Debian 8`, `CentOS 7`, and `Fedora 30`

### Changed
- Lower requirement for Puppet version is now bumped up to `4.10.0` as this is the lowest working version for Hiera 5.
- Change testing matrix to only do acceptance testing on latest Puppet versions.
- Stop managing `group` parameter for `/var/spool/incron` directory and all files that reside there.

## [0.6.0] - 2019-08-08
### Changed
- [GH-6](https://github.com/pegasd/puppet-incron/issues/6): Update `stdlib` version requirements in `metadata.json`.
- Update `REFERENCE.md` with data type since Puppet strings started supporting these.
- PDK update.

## [0.5.0] - 2019-04-09
### Added
- [GH-4](https://github.com/pegasd/puppet-incron/issues/4): Ability to specify user name for `incron::job` resource.
- New dependency: `puppetlabs/concat`.
- Puppet 6 support (no production code changes).

### Changed
- [GH-4](https://github.com/pegasd/puppet-incron/issues/4): `incron::job` now manages jobs through `/var/spool/incron/${user}` instead of `/etc/incron.d/${title}`.
- Validation, Unit, and Acceptance stages now all include Puppet 6.
- Run acceptance tests using new puppet and module install helpers.

### Removed
- [GH-4](https://github.com/pegasd/puppet-incron/issues/4): `$mode` parameter for `incron::job` has now been dropped since it is no longer applicable.

## [0.4.0] - 2018-08-17
### Added
- The module is now PDK-compliant.

### Changed
- Moved reference to a standalone strings-generated `REFERENCE.md`.
- `rspec-puppet-facts` started supporting Ubuntu 18.04, so we can use it now. Sweet!

### Fixed
- `puppetlabs_spec_helper`'s `mock_with` deprecation warning.
- Acceptance tests with latest beaker.

## [0.3.0] - 2018-03-14
### Added
- `$incron::purge_noop` parameter to run purging in `noop` mode.
- Manage allowed or denied users using `$incron::allowed_users` and `$incron::denied_users`.
- Manage package version through `$incron::package_version` parameter.
- The following parameters are now available to configure the incron service management:
  - `$incron::service_manage`
  - `$incron::service_ensure`
  - `$incron::service_enable`
- Acceptance tests for:
  - `incron::whitelist`
  - `$incron::allowed_users`

### Changed
- Split up purging into a separate `incron::purge` manifest.
- 'ensure => file' where applicable.

### Fixed
- `/etc/incron.*` configs now have `mode => '0644'`.

### Removed
- `$incron::dir_mode` parameter.

## [0.2.0] - 2018-03-04
### Added
- Support for lots more inotify events.
- Ability to specify an array of events for `incron::job`.
- Acceptance tests.
- This CHANGELOG.

### Changed
- Purge package @ `incron::remove`.
- Manage service on systemd-based systems (Ubuntu 16.04, 18.04) @ `incron::remove`.

## [0.1.0] - 2017-12-15
### Added
- Initial release.
