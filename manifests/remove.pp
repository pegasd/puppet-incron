# This class handles removal of all incron-related resources.
#
# @api private
class incron::remove {
  if $facts['service_provider'] in ['systemd', 'freebsd'] {
    service { $incron::service_name:
      ensure => stopped,
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
