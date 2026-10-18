{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
# Pinned Antigravity CLI binary; Nix manages its PATH entry.
# Update version, URL and hash together from the upstream release manifest.
stdenv.mkDerivation {
  pname = "antigravity-cli";
  version = "1.1.13-6057583128215552";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.13-6057583128215552/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha256-7cfDK1q0/C5NoDOB/ug+1WbeprVrVvkynNE813lHodk=";
  };

  # Tarball contains a single file `antigravity` at the root.
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib # provides libgcc_s
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ./antigravity $out/bin/agy

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Antigravity CLI (agy) — agent-first replacement for Gemini CLI";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
