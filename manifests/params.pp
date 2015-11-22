#
# Class: kibana::params
#
# This module contains defaults for Kibana
#
class kibana::params {

  # global settings
  $ensure     = 'present'

  # global file properites
  $file_owner = 'root'
  $file_group = 'root'
  $file_mode  = '0644'

  # global module dependencies
  $dependency_class = undef
  $my_class         = undef

  # install package depending on major version
  case $::osfamily {
    default: {
    }
    /(RedHat|redhat|amazon)/: {
      $package = 'kibana'
      $version = 'present'
    }
    /(Debian|debian|Ubuntu|ubuntu)/: {
      $package = 'kibana'
      $version = 'present'
    }
  }
}
