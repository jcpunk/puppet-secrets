# == Class: secrets
class secrets (
  $manage_repo      = $secrets::params::manage_repo,
  $secrets_repos    = $secrets::params::secrets_repos,
  $repo_defaults    = $secrets::params::repo_defaults,
  $install_secrets  = $secrets::params::install_secrets,
  $secrets_defaults = $secrets::params::secrets_defaults,
) {

  validate_bool($manage_repo)
  validate_array($secrets_repos)
  validate_hash($repo_defaults)
  validate_array($install_secrets)
  validate_hash($secrets_defaults)

  if $manage_repo {
    class { 'secrets::repo':
      before        => Class['secrets::install'],
      secrets_repos => $secrets_repos,
      repo_defaults => $repo_defaults,
    }
  }

  class { 'secrets::install':
    install_secrets  => $install_secrets,
    secrets_defaults => $secrets_defaults,
  }

}
