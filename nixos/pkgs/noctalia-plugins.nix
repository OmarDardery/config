{
  stdenv,
  bash,
  luau,
  src,
}:

stdenv.mkDerivation {
  pname = "noctalia-community-plugins";
  version = "aa42b35d2e89550bd2d516718f2c29bccddbe0dc";
  inherit src;

  patches = [
    ./noctalia-screen-toolkit.patch
    ./noctalia-nix-monitor.patch
    ./noctalia-game-launcher.patch
  ];

  dontConfigure = true;
  # Upstream otherwise compiles into the plugin directory at runtime, which
  # cannot work with immutable plugin delivery and is not reproducible.
  buildPhase = ''
    runHook preBuild
    $CC -O2 game-launcher/gamelauncher.c game-launcher/sqlite_reader.c -o game-launcher/gamelauncher
    runHook postBuild
  '';
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    for script in screen-toolkit/scripts/*.sh; do
      ${bash}/bin/bash -n "$script"
    done
    for script in screen-toolkit/*.luau nix-monitor/*.luau game-launcher/*.luau; do
      ${luau}/bin/luau-compile "$script" >/dev/null
    done
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    for plugin in screen-toolkit nix-monitor phone-connect pomodoro tailscale game-launcher; do
      cp -r "$plugin" "$out/$plugin"
    done
    runHook postInstall
  '';
}
