# == Define secrets::addrepo
define secrets::addrepo (
  $repo_provider         = $::secrets::repo_defaults['repo_provider'],
  $repo_user             = $::secrets::repo_defaults['repo_user'],
  $manage_secret_store   = $::secrets::repo_defaults['manage_secret_store'],
  $secret_store          = $::secrets::repo_defaults['secret_store'],
  $secret_store_owner    = $::secrets::repo_defaults['secret_store_owner'],
  $secret_store_group    = $::secrets::repo_defaults['secret_store_group'],
  $secret_store_mode     = $::secrets::repo_defaults['secret_store_mode'],
) {

  $repo_source = $title

  if $manage_secret_store {
    validate_absolute_path($secret_store)

    file {$secret_store:
      ensure => 'directory',
      owner  => $secret_store_owner,
      group  => $secret_store_group,
      mode   => $secret_store_mode,
      before => Vcsrepo[$secret_store],
    }
  }

  exec {"chown ${secret_store}":
    refreshonly => true,
    path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    cwd         => $secret_store,
    command     => "chown -Rh ${secret_store_owner}:${secret_store_group} ${secret_store}",
  }

  vcsrepo {$secret_store:
    ensure   => latest,
    provider => $repo_provider,
    source   => $repo_source,
    user     => $repo_user,
    revision => 'master',
    notify   => Exec["chown ${secret_store}"],
  }
}
