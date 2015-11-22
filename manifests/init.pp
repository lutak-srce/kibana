#
# = Class: kibana
#
class kibana (
  $ensure                = $::kibana::params::ensure,
  $package               = $::kibana::params::package,
  $version               = $::kibana::params::version,
  $configdir             = '/etc/kibana',
  $template              = 'kibana/config.js.erb',
  $webserver_conf_header = 'kibana/conf.header.erb',
  $webserver_conf_body   = 'kibana/conf.body.erb',
  $webserver_conf_footer = 'kibana/conf.footer.erb',
  $webserver             = undef,
  $allow_from            = [ '127.0.0.1', '::1' ],
  $elasticsearch         = 'http://"+window.location.hostname+":9200',
  $dependency_class      = $::kibana::params::dependency_class,
  $my_class              = $::kibana::params::my_class,
  $noops                 = undef,
) inherits kibana::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($package)
  validate_string($version)

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $file_ensure = 'present'
  } else {
    $package_ensure = 'absent'
    $file_ensure    = 'absent'
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  ### Code
  package { 'kibana':
    ensure => $package_ensure,
    name   => $package,
    noop   => $noops,
  }

  ### Determine how to set up web server
  case $webserver {
    'apache': {
      include ::apache
      $service_name       = $::apache::service_name
      $confd_dir          = $::apache::confd_dir
    }
    'nginx':  {
      include ::nginx
      $service_name       = $::nginx::service
      $confd_dir          = $::nginx::confd_dir
    }
    default:  {}
  }

  # kibana webserver configuration (uses concat)
  concat { 'kibana_webserver_config':
    path    => "${confd_dir}/kibana.conf",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[$service_name],
    require => Package['kibana'],
  }
  # fragments
  concat::fragment { 'kibana_webserver_config_header':
    target  => 'kibana_webserver_config',
    content => template($webserver_conf_header),
    order   => '100',
  }
  concat::fragment { 'kibana_webserver_config_footer':
    target  => 'kibana_webserver_config',
    content => template($webserver_conf_footer),
    order   => '300',
  }

  # autoload locations from kibana::locations (from hiera), or set default
  $kibana_locations = hiera_hash('kibana::locations', {})
  if ( $kibana_locations != {} ) {
    create_resources(::Kibana::Location, $kibana_locations)
  } else {
    ::kibana::location { 'kibana':
      index              => 'kibana-int',
      path_config_js     => '/etc/kibana/config.js',
      configdir          => $configdir,
      template           => $template,
      webserver_template => $webserver_conf_body,
      allow_from         => $allow_from,
      elasticsearch      => $elasticsearch,
    }
  }

}
