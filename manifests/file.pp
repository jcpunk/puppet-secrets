# @summary Manages a file with sensitive content, optional POSIX ACLs,
#          and SELinux context attributes.
#
# The namevar is a logical descriptor (e.g. 'krb5 keytab for host foo').
# Set $path explicitly when the title is descriptive rather than a file path.
# Defaults to $title when $title is an absolute path.
# Will always produce a File[$absolute_path] resource
#
# @param content
#   File content. Accepts String or Sensitive[String].
#   Always stored and written as Sensitive to prevent exposure in logs and reports.
#   When sourced from Hiera, declare the key as Sensitive in lookup_options.
#
# @param path
#   Absolute path of the target file. Defaults to $title when $title is a
#   valid absolute path; must be set explicitly otherwise.
#
# @param owner
#   Passed directly to the `file` resource
# @param group
#   Passed directly to the `file` resource
# @param mode
#   Passed directly to the `file` resource
# @param seluser
#   Passed directly to the `file` resource
# @param selrole
#   Passed directly to the `file` resource
# @param seltype
#   Passed directly to the `file` resource
# @param selrange
#   Passed directly to the `file` resource
# @param selinux_ignore_defaults
#   Passed directly to the `file` resource
#
# @param notify_services
#   Service **titles** to try and notify if this changes
#
# @param posix_acl
#   Optional ACL entry hash passed to the posix_acl resource.
#   Requires puppet/posix_acl and setfacl on the target node.
#   action:     set | add | remove
#   permission: Array of ACL entry strings, e.g. ['group:wheel:r--']
#
# @example Descriptive title with explicit path
#   secrets::file { 'krb5 keytab for host foo':
#     path     => '/etc/krb5.keytab',
#     content  => lookup('secrets::krb5_keytab'),
#     owner    => 'root',
#     group    => 'root',
#     mode     => '0400',
#     posix_acl => {
#       action     => 'set',
#       permission => ['group:wheel:r--'],
#     },
#     seluser  => 'system_u',
#     selrole  => 'object_r',
#     seltype  => 'krb5_keytab_t',
#     selrange => 's0',
#   }
#
# @example Path as title (shorthand)
#   secrets::file { '/etc/krb5.keytab':
#     content => lookup('secrets::krb5_keytab'),
#   }
#
define secrets::file (
  Variant[String, Sensitive[String]] $content,
  Variant[String,Integer]            $owner = 'root',
  Variant[String,Integer]            $group = 'root',
  Array                              $notify_services = [],
  Hash                               $posix_acl       = {},
  Boolean                            $selinux_ignore_defaults = false,
  Optional[Stdlib::Absolutepath]     $path     = undef,
  # lint:ignore:optional_default
  Optional[Pattern[/^[0-7]{4}$/]]    $mode     = '0400',
  # lint:endignore
  Optional[String[1]]                $seluser  = undef,
  Optional[String[1]]                $selrole  = undef,
  Optional[String[1]]                $seltype  = undef,
  Optional[String[1]]                $selrange = undef,
) {
  # Resolve target path: explicit $path wins, else $title must be absolute.
  $_path = pick($path, $title)
  assert_type(Stdlib::Absolutepath, $_path) |$expected, $actual| {
    fail("secrets::file[${title}]: 'path' must be an absolute path; got '${_path}'")
  }

  # show_diff and backup are hardcoded. Leaking secrets into reports or the
  # filebucket is not a recoverable mistake.
  file { $_path:
    ensure                  => 'file',
    owner                   => $owner,
    group                   => $group,
    mode                    => $mode,
    content                 => Sensitive($content.unwrap),
    seluser                 => $seluser,
    selrole                 => $selrole,
    seltype                 => $seltype,
    selrange                => $selrange,
    selinux_ignore_defaults => $selinux_ignore_defaults,
    force                   => true,
    show_diff               => false,
    backup                  => false,
  }

  unless empty($notify_services) {
    File[$_path] ~> $notify_services.map |$srv| { Service <| title == $srv |> }
  }

  unless empty($posix_acl) {
    $my_acls = { $_path => $posix_acl }
    create_resources(posix_acl, $my_acls, { 'require' => File[$_path] })
  }
}
