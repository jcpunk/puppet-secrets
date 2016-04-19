# == Class secrets::repo
# mostly it just runs create_resources
class secrets::repo (
  $secrets_repos = $secrets::secrets_repos,
  $repo_defaults = $secrets::repo_defaults,
) inherits secrets {

  validate_hash($secrets_repos)
  validate_hash($repo_defaults)

  create_resources('secrets::addrepo', $secrets_repos, $repo_defaults)

}
