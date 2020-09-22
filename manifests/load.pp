# @summary This type will provide the actual file requested
#
# Find the secret on the system and make the relevant Files
#
# @example
#   secrets::load { '/etc/krb5.keytab':
#     owner => 'root',
#     group => 'root',
#     mode  => '0400',
#     mandatory  => 'true',
#     secretbase => '/my/secrets/repo/on/master',
#     posix_acl  => { 'action'     => 'set',
#                     'permission' => ['group:wheel:r--', ],},
#     selrange   => 's0',
#     seluser    => 'system_u',
#     selrole    => 'object_r',
#     seltype    => 'krb5_keytab_t',
#   }
define secrets::load (
  String               $owner,
  String               $group,
  String               $mode,
  Boolean              $mandatory,
  Stdlib::Absolutepath $secretbase,
  Stdlib::Absolutepath $path  = $title,
  Optional[Array]      $notify_services,
  Optional[Hash]       $posix_acl,
  Optional[String]     $selrange,
  Optional[String]     $seluser,
  Optional[String]     $selrole,
  Optional[String]     $seltype,
  Optional[Boolean]    $selinux_ignore_defaults,
) {
  $mybase = join([$secretbase, $trusted['hostname']], '/')

  if ! find_file($mybase) {
    notify { "missing base ${trusted['hostname']}":
      message => "${trusted['hostname']} does not have secrets on puppet master",
    }
    warning("${trusted['hostname']} does not have secrets on puppet master")
  }

  if $path =~ /\.\.\// {
    fail("The secrets module forbids use of relative paths ('../')")
  }

  # yes I want the literal string '${::hostname}'
  $hostname_replace_string = join(['$', '{::hostname}'], '')
  $real_path = regsubst($path, $secrets::load::hostname_replace_string, $trusted['hostname'], 'G')

  $secret_path = join([$secrets::load::mybase, $secrets::load::path_real], '/')

  if find_file($secret_path) or $mandatory {
    file { $secrets::load::path_real:
      owner                   => $owner,
      group                   => $group,
      mode                    => $mode,
      show_diff               => false,
      force                   => true,
      content                 => file($secret_path),
      selrange                => $selrange,
      seltype                 => $seltype,
      selrole                 => $selrole,
      seluser                 => $seluser,
      selinux_ignore_defaults => $selinux_ignore_defaults,
    }

    if ! empty($notify_services) {
      File[$secrets::load::path_real] {
        notify => Service[$notify_services],
      }
    }

    if ! empty($posix_acl) {
      $my_acls = { $secrets::load::path_real => $posix_acl }
      create_resources(posix_acl, $secrets::load::my_acls, { 'require' => File[$secrets::load::path_real] })
    }
  } else {
    notice ("Did not deploy ${secrets::load::path_real} for ${trusted['hostname']} it does not exist on puppet master")
  }
}
