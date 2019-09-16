# This class handles incron service.
#
# @api private
class incron::service {

  if $::incron::service_manage {
    service { 'incrond':
      ensure     => $::incron::service_ensure,
      enable     => $::incron::service_enable,
      hasrestart => true,
      hasstatus  => true,
    }
  }

}
