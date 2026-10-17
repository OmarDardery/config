# Keep Nixpkgs' FHS wrapper and desktop integration, replacing its retired
# download. Remove this override once the pinned Nixpkgs ships a working release.
{
  jetbrains-toolbox,
  fetchzip,
  buildFHSEnv,
}:
let
  version = "3.8.1.88030";
  src = fetchzip {
    url = "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${version}.tar.gz";
    hash = "sha256-OsuSgC22E2hurQCEnev8GA8hQWLaxg6hclPYHm8crWc=";
  };
in
jetbrains-toolbox.override {
  fetchzip = _: src;
  buildFHSEnv = args: buildFHSEnv (args // { inherit version; });
}
