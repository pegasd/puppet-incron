# Use this to whitelist any system incron jobs you don't want to touch.
# This will make sure that `${incron::incrond_dir}/${title}` won't get deleted
# nor modified.
#
# @example Using incron::whitelist resource
#   incron::whitelist { 'uploader': }
define incron::whitelist {
  include incron

  file { "${incron::incrond_dir}/${name}":
    ensure  => file,
    replace => false,
  }
}
