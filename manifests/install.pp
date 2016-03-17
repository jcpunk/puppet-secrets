# == Class secrets::install
# mostly it just runs create_resources
class secrets::install (
  $install_secrets  = $secrets::install_secrets,
  $secrets_defaults = $secrets::secrets_defaults,
) {

  create_resources('secrets::resources::install', $install_secrets, $secrets_defaults)

}
