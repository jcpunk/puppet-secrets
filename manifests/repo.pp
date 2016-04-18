# == Class secrets::repo
# mostly it just runs create_resources
class secrets::repo (
  $secrets_repos = $::secrets::secrets_repos,
  $repo_defaults = $::secrets::repo_defaults,
) {

  create_resources('secrets::resources::repo', $secrets_repos, $repo_defaults)

}
