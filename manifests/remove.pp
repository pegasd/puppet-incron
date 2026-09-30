# This class handles removal of all incron-related resources.
#
# @api private
class incron::remove {
  # Stop the service before the package (and, on FreeBSD, its rc script) is
  # removed. systemd copes with a missing unit on later runs; the FreeBSD rc
  # provider does not, so use an idempotent exec guarded by `onestatus` there.
  if $facts['service_provider'] == 'systemd' {
    service { $incron::service_name:
      ensure => stopped,
      before => Package['incron'],
    }
  } elsif $facts['service_provider'] == 'freebsd' {
    exec { 'stop incrond':
      command => "service ${incron::service_name} stop",
      onlyif  => "service ${incron::service_name} onestatus",
      path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin', '/usr/local/sbin', '/usr/local/bin'],
      before  => Package['incron'],
    }
  }

  package { 'incron':
    ensure => absent,
  }

  file {
    [
      $incron::incrond_dir,
      $incron::conf_file,
      $incron::allow_file,
      $incron::deny_file,
      $incron::spool_dir,
    ]:
      ensure => absent,
      force  => true,
  }
}
