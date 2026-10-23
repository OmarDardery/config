{
  pkgs,
  inputs,
  flake,
}:
let
  inherit (pkgs) lib;
  profile = flake.lib.deployment;
  home = system.home-manager.users.${profile.username};
  thunar = lib.findFirst (
    package: lib.getName package == "thunar-with-plugins"
  ) null system.environment.systemPackages;
  papers = lib.findFirst (
    package: lib.getName package == "papers"
  ) null system.environment.systemPackages;
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
    gettext
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
  # Parsing generated text does not require realizing the store paths it mentions.
  syntaxFile = name: text: pkgs.writeText name (builtins.unsafeDiscardStringContext text);
  # Legacy configurations belong in disposable test fixtures.
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
      extraSpecialArgs = {
        inherit profile;
        isLaptop = false;
        isNixOS = false;
      };
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
            {
              xdg.configFile.kitty.source = legacyKitty;
              home.file."Pictures/Wallpapers".source = ./assets/wallpapers;
            }
          else
            {
              imports = [
                ./home/kitty.nix
                ./home/desktop.nix
              ];
              xdg.dataFile."noctalia/wallpaper-samples".source = ./assets/wallpapers;
            }
        )
      ];
    };
  fixtures = lib.genAttrs [ "legacy" "current" ] (
    name:
    let
      configuration = (mkFixture (name == "legacy")).config;
      stages = [
        "checkLinkTargets"
        "kittyDeclarativeConfig"
        "linkGeneration"
      ];
    in
    {
      homeDirectory = configuration.home.homeDirectory;
      kitty = lib.getExe pkgs.kitty;
      configHome = configuration.xdg.configHome;
      stateHome = configuration.xdg.stateHome;
      init = configuration.lib.bash.initHomeManagerLib;
      files = configuration.home-files;
      activation =
        (lib.genAttrs stages (
          stage:
          if configuration.home.activation ? ${stage} then configuration.home.activation.${stage}.data else ""
        ))
        // {
          noctaliaWallpaperSamples =
            if name == "legacy" then
              ""
            else
              lib.replaceStrings [ batHome.home.homeDirectory ] [ configuration.home.homeDirectory ]
                batHome.home.activation.noctaliaWallpaperSamples.data;
        };
    }
  );
  system = flake.nixosConfigurations.${profile.hostName}.config;
  gamemodePolicy = pkgs.gamemode;
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
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        osConfig = system;
        profile = profile // {
          homeDirectory = "/fixture home \"quoted\"";
        };
        isNixOS = true;
        desktopEnabled = true;
        isLaptop = false;
      };
      modules = [
        inputs.self.modules.homeManager.desktop
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
      seed = batHome.home.file.".local/bin/desktop-apply".text;
      cache = "";
      bat = pkgs.bat;
      opencodeTui = batHome.xdg.configFile."opencode/tui.json".source;
      noctaliaConfig = batHome.xdg.configFile."noctalia/config.toml".source;
      noctalia = inputs.noctalia.packages.${profile.system}.default;
      samples = ./assets/wallpapers;
      wallpaperSeed = batHome.home.activation.noctaliaWallpaperSamples.data;
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
  editorConfig =
    editorHome:
    pkgs.linkFarm "nvim-test-config" (
      lib.mapAttrsToList
        (name: file: {
          name = lib.removePrefix "nvim/" name;
          path = file.source;
        })
        (lib.filterAttrs (name: file: file.enable && lib.hasPrefix "nvim/" name) editorHome.xdg.configFile)
    );
  editorData =
    editorHome:
    pkgs.linkFarm "nvim-test-data" (
      lib.mapAttrsToList (name: file: {
        name = lib.removePrefix "nvim/" name;
        path = file.source;
      }) (lib.filterAttrs (name: file: file.enable && lib.hasPrefix "nvim/" name) editorHome.xdg.dataFile)
    );
  editorCheck =
    name: executeNotebook: editorHome:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ editorHome.programs.neovim.finalPackage ];
        NOTEBOOK_EXECUTION_TEST = if executeNotebook then "1" else "0";
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_STATE_HOME="$HOME/state"
        export XDG_CACHE_HOME="$HOME/cache"
        export EDITOR_CHECK_DONE="$TMPDIR/editor-check.done"
        mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME/nvim" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
        cp -rs ${editorConfig editorHome}/. "$XDG_CONFIG_HOME/nvim"
        cp -rs ${editorData editorHome}/. "$XDG_DATA_HOME/nvim"
        mkdir -p "$XDG_DATA_HOME/jupyter/kernels/nix-python"
        cp ${editorHome.xdg.dataFile."jupyter/kernels/nix-python/kernel.json".source} \
          "$XDG_DATA_HOME/jupyter/kernels/nix-python/kernel.json"
        # Trigger the UI event that starts LazyVim's deferred configuration.
        timeout 120s nvim --headless \
          --cmd "autocmd User VeryLazy ++once lua vim.schedule(function() local ok, err = xpcall(function() dofile('${./tests/editor-integration.lua}') end, debug.traceback); if not ok then io.stderr:write(err, string.char(10)); vim.cmd('cquit') end end)" \
          -c 'doautocmd UIEnter' \
          -c 'lua vim.wait(110000, function() return false end)'
        test -f "$EDITOR_CHECK_DONE"
        touch "$out"
      '';
  shellFixture = pkgs.writeText "kitty-shell-fixture.json" (
    builtins.toJSON {
      kitty = "${pkgs.kitty}/bin/kitty";
      integration = "${pkgs.kitty}/lib/kitty/shell-integration/zsh";
      zsh = "${pkgs.zsh}/bin/zsh";
      kittyConfig = builtins.unsafeDiscardStringContext home.xdg.configFile."kitty/kitty.conf".text;
      zshrc = home.home.file.".zshrc".text;
      zshenv = builtins.unsafeDiscardStringContext home.home.file.".zshenv".text;
    }
  );
  fixtureJson = pkgs.writeText "kitty-linking-fixtures.json" (builtins.toJSON fixtures);
in
{
  notebook-kernel = scriptCheck "project-notebook-kernel-checks" ''
    ${pkgs.python3.withPackages (ps: [ ps.ipykernel ])}/bin/python3 ${tests}/notebook-kernel.py
  '';
  kitty-shell = scriptCheck "kitty-shell-integration-checks" ''
    export PATH=${lib.makeBinPath [ pkgs.starship ]}:"$PATH"
    python ${tests}/kitty-shell.py ${shellFixture}
  '';
  dotfile-syntax = scriptCheck "generated-dotfile-syntax-checks" ''
    bash -n ${home.home.file.".bashrc".source}
    ${pkgs.zsh}/bin/zsh -n ${syntaxFile "zshrc" home.home.file.".zshrc".text}
    ${pkgs.zsh}/bin/zsh -n ${syntaxFile "zshenv" home.home.file.".zshenv".text}
    bash -n ${syntaxFile "desktop-apply" home.home.file.".local/bin/desktop-apply".text}
    bash -n ${syntaxFile "umbriel-row-action" home.home.file.".local/bin/umbriel-row-action".text}
    bash -n ${syntaxFile "screenshot-window" home.home.file.".local/bin/screenshot-window-umbriel".text}
    ${pkgs.lua5_1}/bin/luac -p ${syntaxFile "init.lua" home.programs.neovim.initLua}
    ${lib.concatMapStringsSep "\n"
      (file: "${pkgs.lua5_1}/bin/luac -p ${syntaxFile "plugin.lua" file.text}")
      (
        builtins.attrValues (
          lib.filterAttrs (
            name: file:
            file.enable && file.text != null && lib.hasPrefix "nvim/" name && lib.hasSuffix ".lua" name
          ) home.xdg.configFile
        )
      )
    }
  '';
  editor-integration = editorCheck "editor-integration-checks" false home;
  editor-notebooks = editorCheck "editor-notebook-checks" true home;
  portable-editor = scriptCheck "native-editor-dotfile-checks" ''
    bash -n ${./pkgs/native-editor-setup.sh}
    ${pkgs.lua5_1}/bin/luac -p ${
      syntaxFile "native-init.lua"
        flake.homeConfigurations.${profile.profileName}.config.xdg.configFile."nvim/init.lua".text
    }
    ${lib.concatMapStringsSep "\n"
      (file: "${pkgs.lua5_1}/bin/luac -p ${syntaxFile "native-plugin.lua" file.text}")
      (
        builtins.attrValues (
          lib.filterAttrs (
            name: file:
            file.enable && file.text != null && lib.hasPrefix "nvim/" name && lib.hasSuffix ".lua" name
          ) flake.homeConfigurations.${profile.profileName}.config.xdg.configFile
        )
      )
    }
  '';
  desktop-integration =
    pkgs.runCommand "desktop-integration-checks"
      {
        nativeBuildInputs = [ pkgs.gnugrep ];
      }
      ''
        test -x ${thunar}/bin/thunar-volman
        test -f ${thunar}/lib/thunarx-3/thunar-archive-plugin.so
        grep -F '${thunar}/bin/' ${thunar}/share/dbus-1/services/org.xfce.Thunar.service
        test -f ${papers}/share/applications/org.gnome.Papers.desktop
        test -f ${pkgs.file-roller}/share/applications/org.gnome.FileRoller.desktop
        test -f ${pkgs.imv}/share/applications/imv.desktop
        test -f ${pkgs.mpv}/share/applications/mpv.desktop
        touch "$out"
      '';
  performance-launchers = scriptCheck "performance-launcher-checks" "python ${tests}/performance-launchers.py ${launcherFixture}";
  # Evaluation alone cannot detect kernel API incompatibilities in the driver.
  nvidia-open = flake.nixosConfigurations.${profile.hostName}.config.hardware.nvidia.package.open;
  noctalia-greeter = system.services.displayManager.noctalia-greeter.package;
  portability = pkgs.writeText "portability-checks.json" (builtins.toJSON portability.checks);
  desktop-migrations = scriptCheck "desktop-migration-checks" "python ${tests}/desktop-migrations.py";
  config-update = scriptCheck "configuration-update-checks" "python ${tests}/config-update.py";
  fastfetch-theme = scriptCheck "fastfetch-theme-checks" ''
    export PATH=${pkgs.lib.makeBinPath [ pkgs.jq ]}:"$PATH"
    python ${tests}/noctalia-fastfetch.py ${inputs.noctalia-templates}
  '';
  reconciliation = scriptCheck "noctalia-reconciliation-checks" "python ${tests}/reconcile-noctalia.py";
  office-convert = scriptCheck "office-conversion-checks" "python ${tests}/office-convert.py";
  native-setup = scriptCheck "native-setup-checks" "python ${tests}/native-setup.py";
  bootstrap = scriptCheck "bootstrap-checks" "bash ${tests}/bootstrap.sh";
  kitty-linking = scriptCheck "kitty-home-manager-linking-checks" "python ${tests}/kitty-linking.py ${fixtureJson}";
  steam-setup = scriptCheck "steam-setup-checks" "python ${tests}/steam-setup.py ${steamFixture}";
  desktop-first-run = scriptCheck "desktop-first-run-checks" "python ${tests}/desktop-first-run.py ${batFixture}";
  zen-window-controls = scriptCheck "zen-window-controls-checks" ''
    bash ${tests}/zen-window-controls.sh ${./pkgs/zen-apply.sh} ${inputs.noctalia-templates}/zen-browser/apply.sh ${./assets/zen-window-controls.css}
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
          inputs.noctalia.packages.${profile.system}.default
          system.programs.umbriel.package
        ];
        exportReferencesGraph = [
          "config-closure"
          home.xdg.configFile."noctalia/config.toml".source
        ];
        PYTHONDONTWRITEBYTECODE = "1";
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_STATE_HOME="$HOME/state"
        export XDG_CACHE_HOME="$HOME/cache"
        mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME/noctalia" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
        noctalia config validate ${home.xdg.configFile."noctalia/config.toml".source}
        python ${tests}/theme-rendering.py \
          ${home.xdg.configFile."noctalia/config.toml".source} \
          ${home.xdg.configFile."umbriel/config.toml".source} \
          ${./assets/wallpapers/dark-mountain.jpg} \
          --closure config-closure \
          --kitty-template ${inputs.noctalia}/assets/templates/kitty/kitty.conf \
          --extension ${portability.fixtures.vscode}
        touch "$out"
      '';
}
