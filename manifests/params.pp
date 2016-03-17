# == Class secrets::params
class secrets::params {
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
}
