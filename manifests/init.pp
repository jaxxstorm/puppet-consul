# == Class: consul
#
# Installs, configures, and manages consul
#
# === Parameters
#
# [*version*]
#   Specify version of consul binary to download.
#
# [*config_hash*]
#   Use this to populate the JSON config file for consul.
#
# [*install_method*]
#   Defaults to `url` but can be `package` if you want to install via a system package.
#
# [*package_name*]
#   Only valid when the install_method == package. Defaults to `consul`.
#
# [*package_ensure*]
#   Only valid when the install_method == package. Defaults to `latest`.
#
# [*ui_package_name*]
#   Only valid when the install_method == package. Defaults to `consul_ui`.
#
# [*ui_package_ensure*]
#   Only valid when the install_method == package. Defaults to `latest`.
#
# [*extra_options*]
#   Extra arguments to be passed to the consul agent
#
# [*init_style*]
#   What style of init system your system uses.
#
# [*purge_config_dir*]
#   Purge config files no longer generated by Puppet
class consul (
  $manage_user       = true,
  $user              = 'consul',
  $manage_group      = true,
  $purge_config_dir  = true,
  $group             = 'consul',
  $join_wan          = false,
  $bin_dir           = '/usr/local/bin',
  $arch              = $consul::params::arch,
  $version           = $consul::params::version,
  $install_method    = $consul::params::install_method,
  $os                = $consul::params::os,
  $download_url      = "https://dl.bintray.com/mitchellh/consul/${version}_${os}_${arch}.zip",
  $package_name      = $consul::params::package_name,
  $package_ensure    = $consul::params::package_ensure,
  $ui_download_url   = "https://dl.bintray.com/mitchellh/consul/${version}_web_ui.zip",
  $ui_package_name   = $consul::params::ui_package_name,
  $ui_package_ensure = $consul::params::ui_package_ensure,
  $config_dir        = '/etc/consul',
  $extra_options     = '',
  $config_hash       = {},
  $config_defaults   = {},
  $service_enable    = true,
  $service_ensure    = 'running',
  $manage_service    = true,
  $install_init      = true,
  $init_style        = $consul::params::init_style,
  $services          = {},
  $watches           = {},
  $checks            = {},
  $acls              = {},
) inherits consul::params {

  validate_bool($purge_config_dir)
  validate_bool($manage_user)
  validate_bool($manage_service)
  validate_hash($config_hash)
  validate_hash($config_defaults)
  validate_hash($services)
  validate_hash($watches)
  validate_hash($checks)
  validate_hash($acls)

  $config_hash_real = merge($config_defaults, $config_hash)
  validate_hash($config_hash_real)

  if $config_hash_real['data_dir'] {
    $data_dir = $config_hash_real['data_dir']
  }

  if $config_hash_real['ui_dir'] {
    $ui_dir = $config_hash_real['ui_dir']
  }

  if ($ui_dir and ! $data_dir) {
    warning('data_dir must be set to install consul web ui')
  }

  if $services {
    create_resources(consul::service, $services)
  }

  if $watches {
    create_resources(consul::watch, $watches)
  }

  if $checks {
    create_resources(consul::check, $checks)
  }

  if $acls {
    create_resources(consul_acl, $acls)
  }

  anchor {'consul_first': }
  ->
  class { 'consul::install': } ->
  class { 'consul::config':
    config_hash => $config_hash_real,
    purge       => $purge_config_dir,
  } ~>
  class { 'consul::run_service': }
  ->
  anchor {'consul_last': }
}
