# This class handles incron service.
#
# @api private
class incron::service {
  if $incron::service_manage {
    service { 'incron':
      ensure     => $incron::service_ensure,
      name       => $incron::service_name,
      enable     => $incron::service_enable,
      hasrestart => true,
      hasstatus  => true,
    }
  }
}
