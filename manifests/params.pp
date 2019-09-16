# == Class: incron::params
#
# Defines defaults for the incron class. Params class should not be called
# directly.
#
class incron::params {

  case $::osfamily {
    'Debian': {
      $service_name = 'incron'
    }

    default: {
      $service_name = 'incrond'
    }
  }

}
