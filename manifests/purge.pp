# Purge the `incron.d` and per-user incron spool directories.
#
# @api private
class incron::purge {
  file { $incron::incrond_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $incron::root_group,
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    noop    => if $incron::purge_noop { true } else { undef },
  }

  file { $incron::spool_dir:
    ensure  => directory,
    owner   => 'root',
    mode    => '1731',
    recurse => true,
    purge   => true,
    force   => true,
    noop    => if $incron::purge_noop { true } else { undef },
  }
}
