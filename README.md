# secrets

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with secrets](#setup)
    * [What secrets affects](#what-secrets-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with secrets](#beginning-with-secrets)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This class will deploy 'secrets' from outside the puppet tree onto your nodes.

It is targeted specifically at items like SSL certificates, ssh host keys,
and kerberos keytabs.  These are items that often have heavily restricted
access.

These are items that you might not be able to store with your manifests.

## Module Description

Ultimately this module simply looks for $secret_store/$::fqdn/<path>
*on your puppet master* and pushes it out to the the node.

If your secrets are stored in a VCS repo (git) you can check it out
automatically first to ensure your secret store is current.

If your module has a range of functionality (installation, configuration,
management, etc.) this is the time to mention it.

## Setup

### What secrets affects

* This module is simply a method to deploy files from the master not
  contained in the puppet root.

### Setup Requirements **OPTIONAL**

None

### Beginning with secrets

For the most basic configuration you can create a secret store with the following commands:

  mkdir -p /etc/puppet/secrets
  mkdir -p /etc/puppet/secrets/myhostname.example.com/etc/
  cat /etc/krb5.keytab > /etc/puppet/secrets/myhostname.example.com/etc/krb5.keytab

Then import the following class:

  class {'secrets':
    install_secrets => {'/etc/krb5.keytab'}
  }

or:
  class {'secrets':
    install_secrets => {'/etc/krb5.keytab' => { group => 'kerberos'}
  }

NOTE: If you have an `organization` fact your path will be /etc/puppet/secrets/${::organization}


## Usage

If you've a VCS repo that will produce the secrets directory structure, you
can checkout the repo.  This feature exists for sites where the puppet master
is managed by a different team than the nodes using the secrets module.  In
that case you are *strongly* advised to ensure the `organization` fact is set
or that your users cannot use the same secret store on the master.

NOTE: if you are going to use the VCS features, make sure your VCS provider
      is installed on the puppet master.

Some secrets may not be present on all nodes.  For example, ssh added
ssh_host_ed25519_key to newer releases.  You may elect to make a secret
optional by setting mandatory=false.  This feature exists so that you can
list off every secret you are managing, but only enforce them on applicable
nodes.

The most fancy version I can think of looks like:

  class {'secrets':
    manage_repo   => true,
    secrets_repos => {'git://somehost/example.git' => {
                                                       'repo_provider' => 'git',
                                                       'repo_user' => 'gituser',
                                                       'manage_secret_store' => true,
                                                       'as_secret_store' => '/my/private/directory',
                                                       'secret_store_owner' => 'puppet',
                                                       'secret_store_group' => 'foreman',
                                                       'secret_store_mode' => '0700',
                                                      },
                      'git://somehost/otherexample.git' => {
                                                       'repo_provider' => 'git',
                                                       'repo_user' => 'gituser',
                                                       'manage_secret_store' => true,
                                                       'as_secret_store' => '/my/other/directory',
                                                       'secret_store_owner' => 'puppet',
                                                       'secret_store_group' => 'foreman',
                                                       'secret_store_mode' => '0700',
                                                      },
                     },
    install_secrets => {'/etc/ssh/ssh_host_rsa_key' => {
                                                          owner => 'root',
                                                          group => 'root',
                                                          mode  => '0400',           
                                                          mandatory => true,
                                                          secret_store   => '/my/private/directory',
                                                          notify_service => [ Service['sshd'], ],
                                                         },
                        '/etc/ssh/ssh_host_rsa_key.pub' => {
                                                          owner => 'root',
                                                          group => 'root',
                                                          mode  => '0444',           
                                                          mandatory => true,
                                                          secret_store   => '/my/private/directory',
                                                          notify_service => [ Service['sshd'], ],
                                                         },
                        '/etc/ssh//etc/ssh/ssh_host_ed25519_key' => {
                                                          owner => 'root',
                                                          group => 'root',
                                                          mode  => '0400',           
                                                          mandatory => false,
                                                          secret_store   => '/my/other/directory',
                                                          notify_service => [ Service['sshd'], ],
                                                         },
                        '/etc/ssh//etc/ssh/ssh_host_ed25519_key.pub' => {
                                                          owner => 'root',
                                                          group => 'root',
                                                          mode  => '0444',           
                                                          mandatory => false,
                                                          secret_store   => '/my/other/directory',
                                                          notify_service => [ Service['sshd'], ],
                                                         },

  }

In this example we check out two repos and deploy our RSA keys to everyone,
and our ED25519 to anyone who has them stored.

If the RSA keys are missing the catalog produces an error, if the ED25519 keys
are missing, the report includes a notice that nothing happend.

Once done, it will restart the sshd service,
though if Service['sshd'] doesn't exist, your catalog will crash.

## Reference

### Defaults if no value is specified
  $manage_repo = false
  $secrets_repos = {}

  if $::organization {
    $secret_path = "/etc/puppet/secrets/${::organization}"
  } else {
    $secret_path = "/etc/puppet/secrets/"
  }

  $repo_defaults = {
    repo_provider       => 'git',
    repo_user           => 'root',
    manage_secret_store => true,
    as_secret_store     => $secret_path,
    secret_store_owner  => 'puppet',
    secret_store_group  => 'puppet',
    secret_store_mode   => '0700',
  }

  $install_secrets = {}
  $secrets_defaults = {
    owner          => 'root',
    group          => 'root',
    mode           => '0400',
    mandatory      => true,
    secret_store   => $repo_defaults['as_secret_store'],
    notify_service => undef,
  }

### Class: secrets
Valid arguments:
. manage_repo
. secrets_repos
. repo_defaults
. install_secrets
. secrets_defaults

Automatically includes all relevent sub classes and resources

### Class: secrets::repo
Valid arguments:
. secrets_repos
. repo_defaults

### Class: secrets::install
Valid arguments:
. install_secrets
. secrets_defaults

### Define secrets::resources::install
Valid argumetns:
. path
. owner
. group
. mode
. notify_service
. secret_store
. mandatory

### Define secrets::resources::repo
Valid argumetns:
. repo_provider
. repo_user
. manage_secret_store
. secret_store
. secret_store_owner
. secret_store_group
. secret_store_mode

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

## Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You may also add any additional sections you feel are
necessary or important to include here. Please use the `## ` header.
