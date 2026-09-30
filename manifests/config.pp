# This class handles incron configuration files.
#
# @api private
class incron::config {
  if !empty($incron::allowed_users) and !empty($incron::denied_users) {
    fail('Either allowed or denied incron users must be specified, not both.')
  }

  file {
    default:
      force => true,
      owner => 'root',
      group => $incron::root_group,
      mode  => '0644';
    $incron::conf_file:
      ensure  => file,
      content => '';
    $incron::allow_file:
      ensure  => if empty($incron::denied_users) { file } else { absent },
      content => join(suffix(['root'] + $incron::allowed_users, "\n"));
    $incron::deny_file:
      ensure  => unless empty($incron::denied_users) { file } else { absent },
      content => join(suffix($incron::denied_users, "\n"));
  }
}
