# @summary Manage secrets on a given host
#
# This class will fetch secrets from the puppet master
# that follow a specific layout.
#
# @param install
#   Secrets to install on the system
# @param defaults
#   Passed as a list of defaults to the installed secrets
#
# @example
#   class {'secrets':
#     install => { '/etc/krb5.keytab' => {
#                       'owner' => 'root',
#                       'group' => 'root',
#                       'mode'  => '0400',
#                       'mandatory'  => 'true',
#                       'secretbase' => '/my/secrets/repo/on/master',
#                       'posix_acl'  => { 'action'     => 'set',
#                                       'permission' => ['group:wheel:r--', ],},
#                       'selrange'   => 's0',
#                       'seluser'    => 'system_u',
#                       'selrole'    => 'object_r',
#                       'seltype'    => 'krb5_keytab_t',  },
#                }
#   }
class secrets (
  Hash $install,
  Hash $defaults
) {
  create_resources('secrets::load', $secrets::install, $secrets::defaults)
}
