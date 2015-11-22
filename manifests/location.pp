#
# = Define: kibana::location
#
# Adds location to nginx or apache
#
# == Parameters
#
define kibana::location (
  $index,
  $path_config_js     = 'UNSET',
  $configdir          = $::kibana::configdir,
  $template           = $::kibana::template,
  $webserver_template = $::kibana::webserver_conf_body,
  $allow_from         = $::kibana::allow_from,
  $elasticsearch      = $::kibana::elasticsearch,
  $noops              = $::kibana::noops,
) {

  include ::kibana

  if ( $path_config_js != 'UNSET' ) {
    $path_config_js_real = $path_config_js
  } else {
    $path_config_js_real = "${configdir}/${name}.js"
  }

  file { "/etc/kibana/${name}.js":
    ensure  => present,
    path    => $path_config_js_real,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($template),
    require => Package['kibana'],
    noop    => $noops,
  }

  ::concat::fragment { "kibana_webserver_config_${name}":
    target  => 'kibana_webserver_config',
    content => template($webserver_template),
    order   => '200',
  }


}
