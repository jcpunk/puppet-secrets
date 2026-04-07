# secrets

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
   - [Requirements](#requirements)
   - [Secret store layout](#secret-store-layout)
   - [Shared secrets](#shared-secrets)
1. [Defines](#defines)
   - [secrets::load](#secretsload)
   - [secrets::file](#secretsfile)
1. [Usage examples](#usage-examples)
1. [Fact interpolation in paths](#fact-interpolation-in-paths)
1. [Limitations](#limitations)

---

## Description

Deploys secret files - SSL certificates, SSH host keys, Kerberos keytabs, and
similar restricted material - from outside the Puppet tree onto managed nodes.

Two defines are provided:

- **`secrets::load`** reads a file from a per-host directory on the Puppet
  server and writes it to the node. Use this when secrets live on disk on the
  server (e.g. an encrypted git checkout).
- **`secrets::file`** writes content supplied directly as a parameter (typically
  from Hiera). Use this when secrets are stored in an external secret manager or
  Hiera eyaml.

Both defines harden the resulting `file` resource identically: `show_diff =>
false` and `backup => false` are unconditional so secrets never appear in Puppet
reports or the filebucket.

---

## Setup

### Requirements

- [`puppet/posix_acl`](https://forge.puppet.com/modules/puppet/posix_acl) and
  `setfacl` on target nodes - required only when `posix_acl` is set.
- [`puppetlabs/stdlib`](https://forge.puppet.com/modules/puppetlabs/stdlib) for
  `Stdlib::Absolutepath` and `pick()`.

### Secret store layout

`secrets::load` looks for files under:

```
${secretbase}/${trusted['hostname']}.${trusted['domain']}/<absolute-path>
```

The default `secretbase` is `/etc/puppetlabs/secrets/`. To deploy
`/etc/krb5.keytab` to `myhostname.example.com`, place the file at:

```
/etc/puppetlabs/secrets/myhostname.example.com/etc/krb5.keytab
```

Create the initial layout with:

```shell
mkdir -p /etc/puppetlabs/secrets/myhostname.example.com/etc
cp /etc/krb5.keytab /etc/puppetlabs/secrets/myhostname.example.com/etc/krb5.keytab
```

If your secrets are version-controlled, use
[puppetlabs-vcsrepo](https://forge.puppet.com/modules/puppetlabs/vcsrepo) to
check out the store on the Puppet server, or see the
[encrypted-git-template](https://github.com/jcpunk/encrypted-git-template) for
an approach that keeps the repo encrypted at rest.

### Shared secrets

`secrets::load` intentionally restricts each host to its own subdirectory.
For secrets shared across hosts (e.g. an HTTPS certificate for a load-balanced
cluster), use symlinks on the Puppet server so that each host has an explicit
entry pointing to the shared material:

```
/etc/puppetlabs/secrets/
├── hostA.example.com/
│   └── etc/pki/ -> ../../_shared/lbcluster.example.com/etc/pki/
├── hostB.example.com/
│   └── etc/pki/ -> ../../_shared/lbcluster.example.com/etc/pki/
└── _shared/
    └── lbcluster.example.com/
        └── etc/pki/
            └── tls.crt
```

This keeps the secret in one place while making the per-host access grant
visible and auditable.

---

## Defines

### secrets::load

Reads a binary file from the per-host secret store on the Puppet server and
deploys it to the node.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `path` | `Stdlib::Absolutepath` | `$title` | Destination path on the node. Defaults to the resource title. |
| `secretbase` | `Stdlib::Absolutepath` | `/etc/puppetlabs/secrets/` | Root of the secret store on the Puppet server. |
| `mandatory` | `Boolean` | `true` | When `true`, a missing secret causes a catalog failure. When `false`, a notice is emitted and no file resource is created. |
| `owner` | `Variant[String,Integer]` | `'root'` | File owner (name or UID). |
| `group` | `Variant[String,Integer]` | `'root'` | File group (name or GID). |
| `mode` | `Optional[String]` | `'0400'` | Octal permission string. |
| `notify_services` | `Array[String]` | `[]` | Service titles to notify on file change. Services must exist in the catalog. |
| `posix_acl` | `Hash` | `{}` | ACL hash forwarded to the `posix_acl` resource. See [POSIX ACLs](#posix-acls) below. |
| `seluser` | `Optional[String]` | `undef` | SELinux user context. |
| `selrole` | `Optional[String]` | `undef` | SELinux role context. |
| `seltype` | `Optional[String]` | `undef` | SELinux type context. |
| `selrange` | `Optional[String]` | `undef` | SELinux range context. |
| `selinux_ignore_defaults` | `Boolean` | `false` | Passed directly to the `file` resource. |

The title supports [fact interpolation](#fact-interpolation-in-paths). Relative
path components (`../`, `/./`) are rejected at catalog compile time.

### secrets::file

Writes content supplied as a parameter to a file on the node. Content is always
handled as `Sensitive` - plain strings are wrapped automatically so they do not
appear in logs or reports.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `content` | `Variant[String, Sensitive[String]]` | - | **Required.** File content. Plain strings are wrapped in `Sensitive()` automatically. For Hiera, set `lookup_options` to type the key as `Sensitive`. |
| `path` | `Optional[Stdlib::Absolutepath]` | `undef` | Destination path. Defaults to `$title` when the title is an absolute path; must be set explicitly when using a descriptive title. |
| `owner` | `Variant[String,Integer]` | `'root'` | File owner (name or UID). |
| `group` | `Variant[String,Integer]` | `'root'` | File group (name or GID). |
| `mode` | `Optional[Pattern[/^[0-7]{4}$/]]` | `'0400'` | Octal permission string. |
| `notify_services` | `Array[String]` | `[]` | Service titles to notify on file change. Services must exist in the catalog. |
| `posix_acl` | `Hash` | `{}` | ACL hash forwarded to the `posix_acl` resource. See [POSIX ACLs](#posix-acls) below. |
| `seluser` | `Optional[String[1]]` | `undef` | SELinux user context. |
| `selrole` | `Optional[String[1]]` | `undef` | SELinux role context. |
| `seltype` | `Optional[String[1]]` | `undef` | SELinux type context. |
| `selrange` | `Optional[String[1]]` | `undef` | SELinux range context. |
| `selinux_ignore_defaults` | `Boolean` | `false` | Passed directly to the `file` resource. |

Always produces a `File[$absolute_path]` resource regardless of the title used.

#### POSIX ACLs

Both defines accept a `posix_acl` hash that is forwarded directly to the
[`posix_acl`](https://forge.puppet.com/modules/puppet/posix_acl) resource, with
`require => File[$path]` added automatically. The hash keys map to `posix_acl`
resource attributes:

```puppet
posix_acl => {
  action     => 'set',            # set | add | remove | purge
  permission => ['group:wheel:r--'],
  provider   => 'setfacl',        # optional, recommended explicit
}
```

---

## Usage examples

### secrets::load - minimal

```puppet
secrets::load { '/etc/krb5.keytab': }
```

Deploys `/etc/krb5.keytab` from the server store. Catalog fails if the file is
absent.

### secrets::load - optional secret with service notification

```puppet
secrets::load { '/etc/ssh/ssh_host_ed25519_key':
  mode      => '0400',
  mandatory => false,
  notify_services => ['sshd.service'],
}
```

Emits a notice (no catalog failure) if the key is not present on the server.
Notifies `Service['sshd.service']` on change - the service must exist in the
catalog.

### secrets::load - full example

```puppet
secrets::load { '/etc/pki/tls/${::hostname}.key':
  owner      => 'root',
  group      => 'root',
  mode       => '0400',
  mandatory  => false,
  secretbase => '/srv/secrets',
  seluser    => 'system_u',
  selrole    => 'object_r',
  seltype    => 'cert_t',
  selrange   => 's0',
  notify_services => ['httpd.service'],
  posix_acl  => {
    action     => 'set',
    permission => ['group:wheel:r--'],
    provider   => 'setfacl',
  },
}
```

### secrets::load - Hiera (recommended)

```yaml
# data/nodes/myhostname.example.com.yaml
secrets::load:
  /etc/krb5.keytab:
    group: kerberos
    notify_services:
      - sssd.service
  /etc/ssh/ssh_host_rsa_key:
    mode: '0400'
    mandatory: true
    notify_services:
      - sshd.service
  /etc/ssh/ssh_host_ed25519_key:
    mode: '0400'
    mandatory: false
    notify_services:
      - sshd.service
```

### secrets::file - path as title

```puppet
secrets::file { '/etc/myapp/db.password':
  content => lookup('myapp::db_password'),
  owner   => 'myapp',
  group   => 'myapp',
  mode    => '0400',
}
```

### secrets::file - descriptive title with explicit path

Using a descriptive title makes Puppet reports readable without exposing path
information in resource names.

```puppet
secrets::file { 'krb5 keytab for host foo':
  path    => '/etc/krb5.keytab',
  content => lookup('secrets::krb5_keytab'),
  owner   => 'root',
  group   => 'root',
  mode    => '0400',
  seluser  => 'system_u',
  selrole  => 'object_r',
  seltype  => 'krb5_keytab_t',
  selrange => 's0',
  posix_acl => {
    action     => 'set',
    permission => ['group:wheel:r--'],
    provider   => 'setfacl',
  },
}
```

### secrets::file - Hiera with Sensitive content

Mark the Hiera key as `Sensitive` so it is never logged during lookup:

```yaml
# data/nodes/myhostname.example.com.yaml
lookup_options:
  myapp::db_password:
    convert_to: 'Sensitive'

myapp::db_password: 'hunter2'
```

```puppet
secrets::file { '/etc/myapp/db.password':
  content => lookup('myapp::db_password'),
}
```

---

## Fact interpolation in paths

`secrets::load` accepts literal fact-reference strings in the title (or `path`)
so that a single Hiera entry can resolve to a host-specific path at catalog
compile time. The following forms are all recognized and replaced with values
from `$trusted`:

| Literal string in path | Replaced with |
|------------------------|---------------|
| `${::hostname}` | `$trusted['hostname']` |
| `${::domain}` | `$trusted['domain']` |
| `${::fqdn}` | `$trusted['hostname'].$trusted['domain']` |
| `${::networking[hostname]}` | `$trusted['hostname']` |
| `${::networking["hostname"]}` | `$trusted['hostname']` |
| `${::networking['hostname']}` | `$trusted['hostname']` |
| `${::networking.hostname}` | `$trusted['hostname']` |
| _(same three forms for `domain` and `fqdn`)_ | _(as above)_ |

`$trusted` facts are used rather than `$facts` to prevent a compromised node
from influencing which secrets it receives.

Example - a single Hiera entry deploys a per-host TLS certificate:

```yaml
secrets::load:
  /etc/pki/tls/certs/${::fqdn}.crt:
    mode: '0444'
    mandatory: false
    notify_services:
      - httpd.service
```

---

## Limitations

- `secrets::load` is a server-side file read. The Puppet server process must
  have read access to the secret store.
- `secrets::file` passes `content` as `Sensitive` unconditionally. The value
  must fit in memory, be renderable as a string, and in the Puppet catalog.
- Relative path components (`../`, `/./`) in titles are rejected at compile time.
- `notify_services` entries must refer to `Service` resources that exist in the
  catalog, or the catalog will fail.
- POSIX ACL support requires the `puppet/posix_acl` module and `setfacl`
  installed on target nodes.
