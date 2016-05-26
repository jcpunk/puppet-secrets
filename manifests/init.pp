# == Class: secrets
class secrets (
  $manage_repo      = $secrets::params::manage_repo,
  $secrets_repos    = $secrets::params::secrets_repos,
  $repo_defaults    = $secrets::params::repo_defaults,
  $install_secrets  = $secrets::params::install_secrets,
  $secrets_defaults = $secrets::params::secrets_defaults,
  $stage            = $secrets::params::stage,
) inherits secrets::params {

  validate_bool($manage_repo)
  validate_string($stage)

  if $manage_repo {
    validate_hash($secrets_repos)
    validate_hash($repo_defaults)

    class { 'secrets::repo':
      secrets_repos => $secrets_repos,
      repo_defaults => $repo_defaults,
    }
    if $install_secrets {
      Class['secrets::repo'] {
        before => Class['secrets::install'],
      }
    }
  }

  if $install_secrets {
    validate_hash($install_secrets)
    validate_hash($secrets_defaults)

    class { 'secrets::load':
      install_secrets  => $install_secrets,
      secrets_defaults => $secrets_defaults,
    }
  }

}
