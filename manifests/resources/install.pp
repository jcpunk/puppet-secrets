# == Define secrets::resources::install
# Define a psudo resource that does the actual deployments
define secrets::resources::install (
  $path = $title,
  $owner = $secrets::params::secrets_defaults['owner'],
  $group = $secrets::params::secrets_defaults['group'],
  $mode = $secrets::params::secrets_defaults['mode'],
  $notify_service = $secrets::params::secrets_defaults['notify_service'],
  $secret_store = $secrets::params::secrets_defaults['secret_store'],
  $mandatory = $secrets::params::secrets_defaults['mandatory'],
) {
  validate_absolute_path($path)
  validate_absolute_path($secret_store)

  $base = "${secret_store}/${::fqdn}"

  if exists($base) {
    if exists("${base}${path}") {
      file{$path:
        owner     => $owner,
        group     => $group,
        mode      => $mode,
        show_diff => false,
        content   => file_on_server("${base}${path}"),
        notify    => $notify_service,
      }
    } elsif $mandatory {
      fail("Mandatory Secret ${path} for ${::fqdn} does not exist in ${secret_store}")
    } else {
    info("Did not deploy ${path} for ${::fqdn} does not exist in ${secret_store}")
    }
  } else {
    warning("${base} does not exist on master")
  }
}
