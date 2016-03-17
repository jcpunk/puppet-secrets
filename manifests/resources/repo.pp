# == Define secrets::resources::repo
define secrets::resources::repo (
  $repo_provider   = $secrets::params::repo_defaults['repo_provider'],
  $repo_user       = $secrets::params::repo_defaults['repo_user'],
  $manage_secret_store = $secrets::params::repo_defaults['manage_secret_store'],
  $secret_store    = $secrets::params::repo_defaults['secret_store'],
  $secret_store_owner    = $secrets::params::repo_defaults['secret_store_owner'],
  $secret_store_group    = $secrets::params::repo_defaults['secret_store_group'],
  $secret_store_mode     = $secrets::params::repo_defaults['secret_store_mode'],
) {

  $repo_source = $title

  if $manage_secret_store {
    validate_absolute_path($secret_store)

    file{$secret_store:
      ensure => 'directory',
      owner  => $secret_store_owner,
      group  => $secret_store_group,
      mode   => $secret_store_mode
      before => Vcsrepo[$secret_store],
    }
  }

  vcsrepo {$secret_store:
    ensure   => latest,
    provider => $repo_provider,
    source   => $repo_source,
    user     => $repo_user,
  }
}
