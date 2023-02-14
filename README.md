# secrets

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with secrets](#setup)
   - [What secrets affects](#what-secrets-affects)
   - [Setup requirements](#setup-requirements)
   - [Beginning with secrets](#beginning-with-secrets)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This class will deploy 'secrets' from outside the puppet tree onto your nodes.

It is targeted specifically at items like SSL certificates, ssh host keys,
and kerberos keytabs. These are items that often have heavily restricted
access.

These are items that you might not be able to store with your manifests.

## Setup

### Setup Requirements

Ultimately this module simply looks for `${secret_store}/$trusted['hostname'].$trusted['domain']/<path>`
**on your puppet server** and pushes it out to the the node.

You can setup an [encrypted git repo](https://github.com/jcpunk/encrypted-git-template) to store things.

If your secrets are in a repo, you can use the [puppetlabs-vcsrepo](https://forge.puppet.com/modules/puppetlabs/vcsrepo) type to check them out.

### Beginning with secrets

For the most basic configuration you can create a secret store with the following commands:

```shell
mkdir -p /etc/puppetlabs/secrets
mkdir -p /etc/puppetlabs/secrets/myhostname.example.com/etc/
cat /etc/krb5.keytab > /etc/puppetlabs/secrets/myhostname.example.com/etc/krb5.keytab
```

Then import the following class:

```puppet
class {'secrets':
  install => {'/etc/krb5.keytab'}
}
```

or:

```puppet
class {'secrets':
  install => {'/etc/krb5.keytab' => { group => 'kerberos'}
}
```

hiera is similar:

```yaml
secrets::load:
  /etc/krb5.keytab:
    group: kerberos
    notify_services:
      - sshd
```

#### Shared secrets

I don't like the idea of letting a host fetch secrets from a non-host specific
directory. But for shared secrets (like the HTTPS cert for a load balanced cluser)
there needs to be some sort of plan.

My suggestion, is to use symbolic links to a directory containing the shared
secrets. This keeps the secrets in one place but also makes clear restrictions
on which hosts can access things.

```shell
├── hostA.example.com
│   └── example -> ../my_shared_secrets/lbhost.example.com/example
├── hostB.example.com
│   └── example -> ../my_shared_secrets/lbhost.example.com/example
└── my_shared_secrets
    └── lbhost.example.com
        └── example
```

## Usage

Some secrets may not be present on all nodes. For example, ssh added
`ssh_host_ed25519_key` to newer releases. You may elect to make a secret
optional by setting `mandatory=false`. This feature exists so that you can
list off every secret you are managing, but only enforce them on applicable
nodes.

The most fancy version I can think of looks like:

```
  class {'secrets':
    install => {'/etc/ssh/ssh_host_rsa_key' => {
                                                owner => 'root',
                                                group => 'root',
                                                mode  => '0400',
                                                mandatory => true,
                                                secret_store   => '/my/private/directory',
                                                notify_services => [ 'sshd', ],
                                               },
              '/etc/ssh/ssh_host_rsa_key.pub' => {
                                                owner => 'root',
                                                group => 'root',
                                                mode  => '0444',
                                                mandatory => true,
                                                secret_store   => '/my/private/directory',
                                                notify_services => [ 'sshd', ],
                                               },
              '/etc/ssh/ssh_host_ed25519_key' => {
                                                owner => 'root',
                                                group => 'root',
                                                mode  => '0400',
                                                mandatory => false,
                                                secret_store   => '/my/other/directory',
                                                notify_services => [ 'sshd', ],
                                               },
              '/etc/ssh/etc/ssh/ssh_host_ed25519_key.pub' => {
                                                owner => 'root',
                                                mode  => '0444',
                                                mandatory => false,
                                                secret_store   => '/my/other/directory',
                                                notify_services => [ 'sshd', ],
                                               },
              '/etc/pki/tls/${::domain}.ca' => {
                                                owner => 'root',
                                                mode  => '0444',
                                                mandatory => false,
                                                notify_services => [ 'httpd', ],
                                               },
              '/etc/pki/tls/${::fqdn}.crt' => {
                                                owner => 'root',
                                                mode  => '0444',
                                                mandatory => false,
                                                notify_services => [ 'httpd', ],
                                               },
              '/etc/pki/tls/${::hostname}.key' => {
                                                owner => 'root',
                                                group => 'root',
                                                mode  => undef,
                                                mandatory => false,
                                                notify_services => [ 'httpd', ],
                                                posix_acl  => { 'action'     => 'set',
                                                              'permission' => ['group:wheel:r--', ],},
                                               },
    defaults => {'group' => 'wheel' },
  }
```

In this example we check out two repos and deploy our RSA keys to everyone,
and our ED25519 to anyone who has them stored.

If the RSA keys are missing the catalog produces an error, if the ED25519 keys
are missing, the report includes a notice that nothing happend.

Any file without the group set directly will default to `wheel`.

Once done, it will restart the sshd service,
though if `Service['sshd']` doesn't exist, your catalog will crash.

It will also deploy public/private keys where the filename is
determined from the system trusted hostname facts and tell `Service['httpd']`.

The key used for `Service['httpd']` will have a POSIX ACL set to let the
`wheel` group also read the file.

The literal strings `${::domain}`, `${::fqdn}`, `${::hostname}`,
`${::network[domain]}`, `${::network[fqdn]}`, `${::network[hostname]}`
`${::network.domain}`, `${::network.fqdn}`, `${::network.hostname}`
will be converted to the values of `$::trusted[domain]`, `$::trusted[hostname]`,
`$::trusted[hostname].$::trusted[domain]` if they are not converted automatically by
your parameter source to an explicit value.

## Limitations

This class tries to only act as a secure file deployment method.

The use of the `$::trusted` facts is by choice to ensure a client cannot swipe
someone else's secrets.
