# == Class secrets::load
# mostly it just runs create_resources
class secrets::load (
  $install_secrets  = $secrets::install_secrets,
  $secrets_defaults = $secrets::secrets_defaults,
) inherits secrets {

  validate_hash($install_secrets)
  validate_hash($secrets_defaults)

  create_resources('secrets::install', $install_secrets, $secrets_defaults)

}
