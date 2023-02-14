# @summary This type will provide the actual file requested
#
# Find the secret on the system and make the relevant Files
#
# @param mandatory
#   Should the catalog crash if this secret doesn't exist
# @param notify_services
#   Service **titles** to try and notify if this changes
# @param posix_acl
#   Set these posix acls (see posix_acl resource)
# @param secretbase
#   The directory to use as the base to start the secret search
# @param path
#   Passed directly to the `file` resource
# @param owner
#   Passed directly to the `file` resource
# @param group
#   Passed directly to the `file` resource
# @param mode
#   Passed directly to the `file` resource
# @param selinux_ignore_defaults
#   Passed directly to the `file` resource
# @param selrange
#   Passed directly to the `file` resource
# @param seluser
#   Passed directly to the `file` resource
# @param selrole
#   Passed directly to the `file` resource
# @param seltype
#   Passed directly to the `file` resource
#
# @example
#   secrets::load { '/etc/krb5.keytab':
#     owner => 'root',
#     group => 'root',
#     mode  => '0400',
#     mandatory  => 'true',
#     secretbase => '/my/secrets/repo/on/server',
#     posix_acl  => { 'action'     => 'set',
#                     'permission' => ['group:wheel:r--', ],},
#     selrange   => 's0',
#     seluser    => 'system_u',
#     selrole    => 'object_r',
#     seltype    => 'krb5_keytab_t',
#   }
define secrets::load (
  Stdlib::Absolutepath    $path  = $title,
  Variant[String,Integer] $owner = 'root',
  Variant[String,Integer] $group = 'root',
  String                  $mode  = '0400',
  Boolean                 $mandatory  = true,
  Stdlib::Absolutepath    $secretbase = '/etc/puppetlabs/secrets/',
  Array                   $notify_services = [],
  Hash                    $posix_acl       = {},
  Boolean                 $selinux_ignore_defaults = false,
  Optional[String]        $selrange = undef,
  Optional[String]        $seluser  = undef,
  Optional[String]        $selrole  = undef,
  Optional[String]        $seltype  = undef,
) {
  $mytrustedfullname = join([$trusted['hostname'], $trusted['domain']], '.')
  $mybase = join([$secretbase, $mytrustedfullname], '/')

  if ! find_file($mybase) {
    warning("${mytrustedfullname} does not have secrets on puppet server")
  }

  if $path =~ /\.\.\// {
    fail("The secrets module forbids use of relative paths ('../')")
  }

  $no_dot_path = regsubst($path, '/\./', '/', 'G')

  $my_dirname = dirname($no_dot_path)
  $my_basename = basename($no_dot_path)

  $normal_path = "${my_dirname}/${my_basename}"

  # lint:ignore:single_quote_string_with_variables
  # yes I want the literal string '${::domain}'
  # yes I want the literal string '${::hostname}'
  # yes I want the literal string '${::fqdn}'
  # yes I want the literal string '${::networking['domain']}', with either quotes or not
  # yes I want the literal string '${::networking['hostname']}', with either quotes or not
  # yes I want the literal string '${::networking['fqdn']}', with either quotes or not
  # yes I want the literal string '${::networking.domain}'
  # yes I want the literal string '${::networking.hostname}'
  # yes I want the literal string '${::networking.fqdn}'
  $path_legacy_domain = regsubst($normal_path, '\$\{::domain\}', $trusted['domain'], 'G')
  $path_legacy_hostname = regsubst($path_legacy_domain, '\$\{::hostname\}', $trusted['hostname'], 'G')
  $path_legacy_fqdn = regsubst($path_legacy_hostname, '\$\{::fqdn\}', $mytrustedfullname, 'G')

  $path_domain_dict = regsubst($path_legacy_fqdn, '\$\{::networking\[[\'"]?domain[\'"]?\]\}', $trusted['domain'], 'G')
  $path_hostname_dict = regsubst($path_domain_dict, '\$\{::networking\[[\'"]?hostname[\'"]?\]\}', $trusted['hostname'], 'G')
  $path_fqdn_dict = regsubst($path_hostname_dict, '\$\{::networking\[[\'"]?fqdn[\'"]?\]\}', $mytrustedfullname, 'G')

  $path_domain_dot = regsubst($path_fqdn_dict, '\$\{::networking\.domain\}', $trusted['domain'], 'G')
  $path_hostname_dot = regsubst($path_domain_dot, '\$\{::networking\.hostname\}', $trusted['hostname'], 'G')
  $path_fqdn_dot = regsubst($path_hostname_dot, '\$\{::networking\.fqdn\}', $mytrustedfullname, 'G')

  $path_real = $path_fqdn_dot
  # lint:endignore

  $secret_path = join([$mybase, $path_real], '')

  if find_file($secret_path) or $mandatory {
    file { $path_real:
      owner                   => $owner,
      group                   => $group,
      mode                    => $mode,
      show_diff               => false,
      force                   => true,
      content                 => Sensitive(binary_file($secret_path)),
      selrange                => $selrange,
      seltype                 => $seltype,
      selrole                 => $selrole,
      seluser                 => $seluser,
      selinux_ignore_defaults => $selinux_ignore_defaults,
    }

    unless empty($notify_services) {
      File[$path_real] ~> $notify_services.map |$srv| { Service <| title == $srv |> }
    }

    unless empty($posix_acl) {
      $my_acls = { $path_real => $posix_acl }
      create_resources(posix_acl, $my_acls, { 'require' => File[$path_real] })
    }
  } else {
    notice ("Did not deploy ${path_real} for ${mytrustedfullname} it does not exist on puppet server")
  }
}
