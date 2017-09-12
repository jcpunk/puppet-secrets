# == Define secrets::install
# Define a psudo resource that does the actual deployments
define secrets::install (
  $path = $title,
  $owner = $secrets::secrets_defaults['owner'],
  $group = $secrets::secrets_defaults['group'],
  $mode = $secrets::secrets_defaults['mode'],
  $selrange = $secrets::secrets_defaults['selrange'],
  $selrole = $secrets::secrets_defaults['selrole'],
  $seltype = $secrets::secrets_defaults['seltype'],
  $seluser = $secrets::secrets_defaults['seluser'],
  $secret_store = $secrets::secrets_defaults['secret_store'],
  $mandatory = $secrets::secrets_defaults['mandatory'],
) {
  validate_absolute_path($path)
  validate_absolute_path($secret_store)

  $base = "${secret_store}/${::fqdn}"

  # yes I really want the literal non-interp string
  $fqdn_replace_string = join(['$', '{::fqdn}'], '')
  $hostname_replace_string = join(['$', '{::hostname}'], '')

  $path_fqdn = regsubst($path, $fqdn_replace_string, $::fqdn, 'G')
  $path_hostname = regsubst($path_fqdn, $hostname_replace_string, $::hostname, 'G')


  $path_real = $path_hostname

  if ! exists($base) {
    notify {"missing base ${::fqdn}":
      message => "${::fqdn} does not have secrets on master",
    }
    warning("${::fqdn} does not have secrets on master")
  }

  if exists("${base}${path_real}") or $mandatory {
    file {$path_real:
      owner     => $owner,
      group     => $group,
      mode      => $mode,
      show_diff => false,
      content   => file_on_server("${base}${path_real}"),
    }

    if $::selinux {
      File[$path_real] {
        selrange => $selrange,
        selrole  => $selrole,
        seltype  => $seltype,
        seluser  => $seluser,
      }
    }
  } else {
    notice ("Did not deploy ${path_real} for ${::fqdn} does not exist in ${secret_store}")
  }
}
