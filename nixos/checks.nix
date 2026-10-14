{
  pkgs,
  inputs,
  flake,
}:
let
  inherit (pkgs) lib;
  profile = flake.lib.deployment;
  home = flake.homeConfigurations.${profile.profileName}.config;
  portability = import ./tests/portability.nix { inherit flake; };
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  source = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      builtins.baseNameOf path != "result"
      && builtins.baseNameOf path != "__pycache__"
      && !(lib.hasSuffix ".pyc" path);
  };
  tests = "${source}/tests";
  shellInputs = with pkgs; [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    git
    util-linux
    python
  ];
  scriptCheck =
    name: command:
    pkgs.runCommand name
      {
        nativeBuildInputs = shellInputs;
        PYTHONDONTWRITEBYTECODE = "1";
      }
      ''
        ${command}
        touch "$out"
      '';
  # Historical files belong in disposable fixtures, not the live dotfiles.
  legacyKitty = pkgs.runCommand "legacy-kitty-fixture" { } ''
    mkdir -p "$out"
    printf 'font_size 31\ninclude ~/.local/state/noctalia/theme/kitty.conf\n' > "$out/kitty.conf"
    printf 'old image\n' > "$out/legacy-image.png"
    printf 'custom settings\n' > "$out/custom.conf"
  '';
  mkFixture =
    legacy:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.isLaptop = false;
      modules = [
        {
          home.username = "fixture";
          home.homeDirectory = "/fixture";
          home.stateVersion = "26.05";
          xdg.configHome = "/fixture/config \"custom\"";
          xdg.stateHome = "/fixture/state \"custom\"";
        }
        (
          if legacy then
            { xdg.configFile.kitty.source = legacyKitty; }
          else
            { imports = [ ./home/desktop.nix ]; }
        )
      ];
    };
  fixtures = lib.genAttrs [ "legacy" "current" ] (
    name:
    let
      configuration = (mkFixture (name == "legacy")).config;
      stages = [
        "checkLinkTargets"
        "kittyDirectoryMigration"
        "linkGeneration"
        "kittyWritableConfig"
      ];
    in
    {
      homeDirectory = configuration.home.homeDirectory;
      configHome = configuration.xdg.configHome;
      stateHome = configuration.xdg.stateHome;
      init = configuration.lib.bash.initHomeManagerLib;
      files = configuration.home-files;
      activation = lib.genAttrs stages (
        stage:
        if configuration.home.activation ? ${stage} then configuration.home.activation.${stage}.data else ""
      );
    }
  );
  system = flake.nixosConfigurations.${profile.hostName}.config;
  gamemodePolicy = lib.findFirst (
    package: lib.getName package == "gamemode-polkit-policy"
  ) null system.environment.systemPackages;
  steamPackages = import ./pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    colorsFile = "/fixture/steam.css";
  };
  steamFixture = pkgs.writeText "steam-setup-fixture.json" (
    builtins.toJSON {
      targets = [
        "${steamPackages.millennium}/lib/libmillennium_bootstrap_x86.so"
        "${steamPackages.millennium}/lib/libmillennium_bootstrap_hhx64.so"
        "${steamPackages.material}"
      ];
    }
  );
  batHome =
    (flake.homeConfigurations.${profile.profileName}.extendModules {
      specialArgs.profile = profile // {
        homeDirectory = "/fixture home \"quoted\"";
      };
      modules = [
        {
          xdg.configHome = "/fixture home \"quoted\"/config \"custom\"";
          xdg.cacheHome = "/fixture home \"quoted\"/cache \"custom\"";
        }
      ];
    }).config;
  batFixture = pkgs.writeText "bat-seed-fixture.json" (
    builtins.toJSON {
      homeDirectory = batHome.home.homeDirectory;
      configHome = batHome.xdg.configHome;
      cacheHome = batHome.xdg.cacheHome;
      init = batHome.lib.bash.initHomeManagerLib;
      seed = batHome.home.activation.initializeNoctaliaBat.data;
      cache = batHome.home.activation.batCache.data;
      bat = batHome.programs.bat.package;
    }
  );
  launcherMocks = pkgs.runCommand "performance-launcher-mocks" { } ''
    mkdir -p "$out/bin"
    for command in powerprofilesctl gamemoderun test-target; do
      printf '#!${python}/bin/python3\n' > "$out/bin/$command"
      cat ${./tests/performance-launcher-mock.py} >> "$out/bin/$command"
      chmod +x "$out/bin/$command"
    done
  '';
  testLaunchers = import ./pkgs/performance-launchers.nix {
    inherit pkgs;
    isNixOS = true;
    isLaptop = true;
    powerProfiles = launcherMocks;
    gameMode = launcherMocks;
  };
  portableLaunchers = import ./pkgs/performance-launchers.nix {
    inherit pkgs;
    isNixOS = false;
    isLaptop = false;
    gameMode = launcherMocks;
  };
  launcherFixture = pkgs.writeText "performance-launcher-fixture.json" (
    builtins.toJSON {
      performance = lib.getExe testLaunchers.performanceRun;
      game = lib.getExe testLaunchers.gameRun;
      portableGame = lib.getExe portableLaunchers.gameRun;
      target = "${launcherMocks}/bin/test-target";
    }
  );
  fixtureJson = pkgs.writeText "kitty-linking-fixtures.json" (builtins.toJSON fixtures);
in
{
  performance-launchers = scriptCheck "performance-launcher-checks" "python ${tests}/performance-launchers.py ${launcherFixture}";
  portability = pkgs.writeText "portability-checks.json" (builtins.toJSON portability.checks);
  desktop-migrations = scriptCheck "desktop-migration-checks" "python ${tests}/desktop-migrations.py";
  reconciliation = scriptCheck "noctalia-reconciliation-checks" "python ${tests}/reconcile-noctalia.py";
  bootstrap = scriptCheck "bootstrap-checks" "bash ${tests}/bootstrap.sh";
  host-setup = scriptCheck "host-setup-checks" "bash ${tests}/host-setup.sh";
  kitty-linking = scriptCheck "kitty-home-manager-linking-checks" "python ${tests}/kitty-linking.py ${fixtureJson}";
  steam-setup = scriptCheck "steam-setup-checks" "python ${tests}/steam-setup.py ${steamFixture}";
  bat-first-run = scriptCheck "bat-first-run-checks" "python ${tests}/bat-first-run.py ${batFixture}";
  zen-window-controls = scriptCheck "zen-window-controls-checks" ''
    bash ${tests}/zen-window-controls.sh ${./pkgs/zen-apply.sh} ${inputs.noctalia-templates}/zen-browser/apply.sh ${./dotfiles/zen/zen-window-controls.css}
  '';
  rust-toolchain =
    pkgs.runCommand "rust-toolchain-checks"
      {
        nativeBuildInputs = [
          pkgs.rustc
          pkgs.cargo
          pkgs.clippy
          pkgs.rustfmt
          pkgs.stdenv.cc
        ];
      }
      ''
        export CARGO_HOME="$TMPDIR/cargo-home"
        mkdir -p src "$CARGO_HOME"
        cat > Cargo.toml <<'EOF'
        [package]
        name = "toolchain-smoke"
        version = "0.1.0"
        edition = "2024"
        EOF
        cat > src/main.rs <<'EOF'
        fn main() {
            println!("Rust toolchain ready");
        }
        EOF
        cargo build --offline
        cargo clippy --offline -- -D warnings
        cargo fmt --check
        test "$(./target/debug/toolchain-smoke)" = "Rust toolchain ready"
        touch "$out"
      '';
  gamemode-authorization = pkgs.runCommand "gamemode-authorization-checks" { } ''
    test -f ${gamemodePolicy}/share/polkit-1/actions/com.feralinteractive.GameMode.policy
    test -f ${gamemodePolicy}/share/polkit-1/rules.d/gamemode.rules
    cmp ${gamemodePolicy}/share/polkit-1/rules.d/gamemode.rules ${pkgs.gamemode}/share/polkit-1/rules.d/gamemode.rules
    touch "$out"
  '';
  theme-rendering =
    pkgs.runCommand "noctalia-theme-rendering-checks"
      {
        nativeBuildInputs = [
          python
          home.programs.noctalia.package
          home.programs.umbriel.package
        ];
        exportReferencesGraph = [
          "config-closure"
          home.xdg.configFile."noctalia/config.toml".source
        ];
        PYTHONDONTWRITEBYTECODE = "1";
      }
      ''
        python ${tests}/theme-rendering.py \
          ${home.xdg.configFile."noctalia/config.toml".source} \
          ${home.xdg.configFile."umbriel/config.toml".source} \
          ${./dotfiles/Pictures/Wallpapers/dark-mountain.jpg} \
          --closure config-closure \
          --kitty-template ${inputs.noctalia}/assets/templates/kitty/kitty.conf \
          --extension ${portability.fixtures.vscode}
        touch "$out"
      '';
}
