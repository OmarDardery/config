# Doom Emacs, with every elisp package resolved by Nix rather than fetched at
# runtime — the same bargain as ../development/lazyvim.nix, reached a different
# way.
#
# LazyVim needs its plugin list written out by hand, because lazy.nvim has no
# way to tell Nix what a spec resolves to. Doom does: nix-doom-emacs-unstraightened
# runs Doom's own CLI to export the dependency list implied by the `doom!` block
# below, then hands that to emacsWithPackages. So enabling a language here is one
# line in `init.el` plus its language server in `extraBinPackages` — Doom's own
# straight.el package manager never runs, and nothing is downloaded on first start.
#
# Everything lives in this file. The DOOMDIR is built from the strings below into
# a store path rather than kept as loose dotfiles, which is why it is read-only
# and why `doom sync` / `doom upgrade` are neither needed nor possible: packages
# move when you bump the flake.
{ pkgs, lib, inputs, config, ... }:
let
  toolchain = import ./toolchain.nix { inherit pkgs; };

  # ── Language servers and tools ────────────────────────────────────────
  # Doom's `+lsp` flags call eglot, which finds servers by looking for known
  # binary names on PATH. The shared set in ./toolchain.nix covers almost all of
  # them — names there were checked against eglot's own `eglot-server-programs`
  # table in Emacs 30, so they match what it actually searches for (e.g.
  # `docker-langserver`, which is the binary the dockerfile-language-server
  # package ships under). Listed here is only what Doom needs on top, and the
  # one place where Doom and the other editors genuinely want different tools.
  languageServers = toolchain.languageServers ++ (with pkgs; [
    # TypeScript / JavaScript. Note this is NOT vtsls, which the Neovim and
    # VSCodium configs use: eglot's built-in entry is
    # typescript-language-server, and teaching it about vtsls would be extra
    # config for no gain. Both are on PATH; eglot simply picks this one.
    typescript-language-server
    # Embedded. platformio-mode shells out to `platformio`.
    platformio-core
    # Doom itself leans on these for search, project detection and :tools magit.
    ripgrep
    fd
    git
    coreutils
    gnutls
  ]);

  # ── Notebook support ──────────────────────────────────────────────────
  # `:lang org +jupyter` drives kernels through emacs-jupyter, which talks to a
  # real Jupyter install over ZeroMQ. That install is the shared env from
  # ./toolchain.nix — VSCodium's Jupyter extension runs against the same one, so
  # a notebook opened in either editor sees the same packages.
  #
  # Deliberately not using `:tools ein`: its own module README says "This module
  # is deprecated and will be replaced with a new module based on code-cells.el"
  # and "This module needs a maintainer." org-babel is the path that is actually
  # maintained, and is the reason to run Emacs for notebooks in the first place.
  inherit (toolchain) jupyterPython;

  # The kernelspec nixpkgs ships inside the python env has `"python"` as its
  # argv[0] — a bare name, resolved against PATH at launch. Doom's PATH puts the
  # user profile ahead of extraBinPackages, so that resolves to the plain
  # python3 from ./default.nix, which has no ipykernel, and every kernel start
  # fails with ModuleNotFoundError. Naming the interpreter absolutely removes
  # the ambiguity; JUPYTER_PATH below puts this ahead of the env's own copy.
  jupyterKernels = pkgs.writeTextDir "kernels/python3/kernel.json" (builtins.toJSON {
    argv = [
      "${jupyterPython}/bin/python3"
      "-m"
      "ipykernel_launcher"
      "-f"
      "{connection_file}"
    ];
    display_name = "Python 3 (nix)";
    language = "python";
  });

  # ── DOOMDIR ───────────────────────────────────────────────────────────
  # init.el chooses modules, packages.el adds anything Doom has no module for,
  # config.el is ordinary configuration. Built into the store so the whole thing
  # is a property of this file.
  doomDir = pkgs.runCommand "doomdir" { } ''
    mkdir -p $out
    cp ${initEl} $out/init.el
    cp ${packagesEl} $out/packages.el
    cp ${configEl} $out/config.el
  '';

  initEl = pkgs.writeText "init.el" ''
    ;;; init.el -*- lexical-binding: t; -*-
    ;; Generated from home/development/doom-emacs.nix. Editing the copy in the
    ;; Nix store does nothing; edit the Nix file and rebuild.

    (doom! :completion
           (corfu +orderless)          ; completion popup
           vertico                     ; the minibuffer half of it

           :ui
           doom                        ; the look
           dashboard
           hl-todo
           modeline
           ophints
           (popup +defaults)
           (vc-gutter +pretty)         ; git marks in the fringe
           vi-tilde-fringe
           workspaces

           :editor
           (evil +everywhere)          ; vim keys, including in every other mode
           file-templates
           fold
           (format +onsave)            ; matches LazyVim's format-on-save
           snippets
           (whitespace +guess +trim)

           :emacs
           dired
           electric
           tramp
           undo
           vc

           :term
           vterm                       ; the good terminal emulation

           :checkers
           (syntax +flymake)           ; flymake, because eglot reports through it

           :tools
           direnv                      ; picks up the project envs from ../nix-tools.nix
           (docker +lsp +tree-sitter)
           (eval +overlay)             ; run a region, see the result inline
           lookup
           (lsp +eglot)                ; eglot, not lsp-mode: no package auto-install
           magit
           tree-sitter                 ; also supplies the conf-toml → toml-ts remap

           :os
           (:if (featurep :system 'macos) macos)

           :lang
           (cc +lsp +tree-sitter)      ; C, C++, and the embedded work
           data                        ; csv and friends
           emacs-lisp
           (go +lsp +tree-sitter)
           (javascript +lsp +tree-sitter)
           (json +lsp +tree-sitter)
           (lua +lsp +tree-sitter)
           (markdown +lsp +tree-sitter)
           (nix +lsp +tree-sitter)
           (org +jupyter)              ; notebooks, via org-babel
           (python +lsp +tree-sitter)
           (rust +lsp +tree-sitter)
           (sh +lsp)
           (yaml +lsp +tree-sitter)

           :config
           (default +bindings +smartparens))
  '';

  packagesEl = pkgs.writeText "packages.el" ''
    ;; -*- no-byte-compile: t; -*-
    ;;; packages.el

    ;; Doom has no PlatformIO module — I checked all 68 :lang and 21 :tools
    ;; modules. This is the same situation as Neovim, where the plugin also had
    ;; to be added by hand, except that here the package is already in nixpkgs
    ;; so unstraightened resolves it without a fetcher or a hash.
    ;;
    ;; Worth knowing: upstream platformio-mode is quieter than its Neovim
    ;; counterpart, and nixpkgs carries a 2021 snapshot of it. clangd does the
    ;; heavy lifting either way; this only adds the build/upload/monitor commands.
    (package! platformio-mode)
  '';

  configEl = pkgs.writeText "config.el" ''
    ;;; config.el -*- lexical-binding: t; -*-

    (setq user-full-name "OmarDardery"
          user-mail-address "oadardery@gmail.com")

    ;; JetBrains Mono Nerd Font is installed system-wide in ../desktop.nix, and
    ;; doom-modeline wants the Nerd Font glyphs.
    ;;
    ;; The `.0' on the size is load-bearing. `:size' is read as PIXELS when it is
    ;; an integer and POINTS when it is a float, and only the point path gets
    ;; scaled by the display DPI. niri runs this output at scale 1.5 (2560x1600
    ;; physical, 1706x1066 logical), so kitty's `font_size 14.0' lands at ~28
    ;; physical pixels while an integer `:size 14' here rendered at exactly 14 —
    ;; half the size, which is why Emacs looked tiny next to the terminal.
    ;; As a float it tracks the scale, so this stays right if the display changes.
    (setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14.0)
          ;; Presentation size, toggled with `SPC t b'.
          doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 22.0)
          doom-theme 'doom-tokyo-night)

    (setq display-line-numbers-type 'relative)

    ;; ── Language servers eglot does not know about ─────────────────────
    ;; Everything else resolves from eglot's built-in table. These two have no
    ;; entry there, so without this they would silently start no server.
    (after! eglot
      (add-to-list 'eglot-server-programs
                   '((markdown-mode markdown-ts-mode gfm-mode) . ("marksman" "server")))
      (add-to-list 'eglot-server-programs
                   '((conf-toml-mode toml-ts-mode) . ("taplo" "lsp" "stdio")))

      ;; Rust is handled below, not here — see the rustic-analyzer-command note.
      )

    ;; ── Rust ───────────────────────────────────────────────────────────
    ;; Rust is the one server that needs an absolute path. `extraBinPackages' is
    ;; *appended* to Doom's PATH rather than prepended (confirmed by
    ;; `executable-find' resolving platformio to the user profile), so the rustup
    ;; shim in the profile wins over the rust-analyzer package. The active
    ;; toolchain has no rust-analyzer component, so that shim "falls back" to the
    ;; next match on PATH — itself — and the server dies with "infinite recursion
    ;; detected" on every Rust buffer. Same trap as in ./lazyvim.nix.
    ;;
    ;; The fix has to go through this variable rather than through
    ;; `eglot-server-programs'. Doom's :lang rust remaps rust-mode to
    ;; rustic-mode, and `rustic-setup-eglot' (rustic-lsp.el:132) prepends its own
    ;; entry built from `rustic-analyzer-command' when the mode starts — after
    ;; any `after! eglot' block has run, so it shadows an entry added there.
    ;; Verified: with the eglot entry alone, `eglot--guess-contact' in a .rs
    ;; buffer still reported the bare ("rust-analyzer").
    (setq rustic-analyzer-command '("${pkgs.rust-analyzer}/bin/rust-analyzer"))

    ;; ── Formatters ─────────────────────────────────────────────────────
    ;; `:editor format +onsave' runs apheleia, which picks a formatter from
    ;; `apheleia-mode-alist'. Its defaults were written for a machine where you
    ;; pip-install whatever it names; here the binary set is fixed by Nix, so
    ;; three of its entries have to be corrected or every save in those modes
    ;; fails with "command not found".
    (after! apheleia
      ;; Default is black, which is not installed and is not what the Neovim
      ;; side uses either. ruff does both the import sort and the format, and
      ;; is already here for linting.
      (dolist (mode '(python-mode python-ts-mode))
        (setf (alist-get mode apheleia-mode-alist) '(ruff-isort ruff)))

      ;; apheleia ships no markdown entry at all and Doom's markdown module adds
      ;; none, so markdown silently never formatted. prettier is installed for
      ;; the JS/TS/YAML side already.
      (dolist (mode '(markdown-mode markdown-ts-mode gfm-mode))
        (setf (alist-get mode apheleia-mode-alist) 'prettier-markdown))

      ;; apheleia defaults dockerfiles to dprint; Doom's docker module overrides
      ;; that to dockfmt (tools/docker/config.el:5). Neither is packaged here,
      ;; and neither is worth adding — LazyVim only lints Dockerfiles too.
      (dolist (mode '(dockerfile-mode dockerfile-ts-mode))
        (setf (alist-get mode apheleia-mode-alist) nil)))

    ;; ── Notebooks ──────────────────────────────────────────────────────
    ;; Kernels come from the pinned env, with an absolute interpreter — see the
    ;; jupyterKernels comment in doom-emacs.nix for why the stock kernelspec
    ;; cannot be trusted here.
    (setenv "JUPYTER_PATH" "${jupyterKernels}")
    (setq org-babel-python-command "${jupyterPython}/bin/python3")

    ;; Deliberately NOT calling org-babel-do-load-languages. Doom neutralises it
    ;; outright — lang/org/config.el does
    ;;   (advice-add #'org-babel-do-load-languages :override #'ignore)
    ;; — and lazy-loads each ob-* library the first time a block of that
    ;; language is executed. The +jupyter flag registers a hook on
    ;; `+org-babel-load-functions' that pulls in ob-jupyter for any language
    ;; named `jupyter-*'. So a block header of
    ;;   #+begin_src jupyter-python :session py
    ;; is what activates all of this; a plain `python' block runs through
    ;; ob-python instead and never touches a kernel.
    (after! org
      ;; Code in a notebook you opened on purpose is code you meant to run;
      ;; without this every execution prompts.
      (setq org-confirm-babel-evaluate nil))

    ;; ── Embedded ───────────────────────────────────────────────────────
    ;; clangd provides completion and diagnostics once `pio run -t compiledb`
    ;; has produced a compile_commands.json; platformio-mode adds the
    ;; build/upload/monitor commands on its own `C-c i' prefix.
    ;;
    ;; No `:after cc-mode' here, and that is deliberate. `:lang cc +tree-sitter'
    ;; remaps c-mode/c++-mode to c-ts-mode/c++-ts-mode, and Emacs 30's
    ;; c-ts-mode.el requires only treesit and c-ts-common — never cc-mode. So a
    ;; `.cpp' file loads c++-ts-mode without the cc-mode feature ever being
    ;; provided, `:after' would never fire, and the hook below would never be
    ;; registered. Hooking the four modes directly works for both worlds.
    (use-package! platformio-mode
      :hook ((c-mode c-ts-mode c++-mode c++-ts-mode) . platformio-conditionally-enable))

    ;; ── Writable escape hatch ──────────────────────────────────────────
    ;; Everything above this line lives in a read-only store path, so trying
    ;; something out means editing doom-emacs.nix and rebuilding. This file does
    ;; not: drop elisp in ~/.config/doom-user/config.el and restart the daemon
    ;; (`systemctl --user restart emacs') to pick it up.
    ;;
    ;; It loads last, so it can override anything set above. The limit is the
    ;; same one the Neovim side has with its linkFarm: configuration is free,
    ;; but a new *package* still has to come from Nix, because there is no
    ;; straight.el here to fetch one.
    ;;
    ;; The Neovim equivalent needs no such hook — home-manager only symlinks the
    ;; leaf files, so ~/.config/nvim/lua/plugins/ is a real directory and any
    ;; .lua dropped in it is picked up by the `{ import = "plugins" }' spec.
    (let ((f (expand-file-name "doom-user/config.el"
                               (or (getenv "XDG_CONFIG_HOME") "~/.config"))))
      (when (file-readable-p f)
        (load f nil 'nomessage)))
  '';
in
{
  imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

  programs.doom-emacs = {
    enable = true;
    inherit doomDir;

    # Writable state — the package cache, ELN cache and persisted history. The
    # DOOMDIR above is read-only, so everything mutable has to land here.
    doomLocalDir = "${config.xdg.dataHome}/nix-doom";

    # Installs `emacs`, not `doom-emacs`. Nothing else on this machine wants a
    # vanilla Emacs, so there is nothing to collide with.
    provideEmacs = true;

    # Packages Doom pins to a commit that nixpkgs/emacs-overlay does not carry
    # have to be fetched directly. The default does that with `git clone`, which
    # pulls every ref of every repo — the first build spends most of its time
    # downloading pull-request refs and tags nobody wants. This switches to
    # Nix's github fetcher, which grabs one tarball per package instead.
    # Upstream calls it experimental only because that fetcher is documented as
    # "subject to change"; turn it off if a future Nix breaks fetching.
    experimentalFetchTree = true;

    # Doom looks these up by name at runtime, the way the neovim wrapper does
    # for LazyVim. Overriding the default drops ripgrep/git/fd, so they are
    # listed explicitly above.
    extraBinPackages = languageServers ++ [ jupyterPython ];

    # `:tools tree-sitter` uses Emacs 30's built-in treesit, which loads grammars
    # as shared objects from a search path rather than compiling them. This is
    # the same gap as on the Neovim side — grammars are never automatic — and
    # unstraightened's README calls it out.
    #
    # Its documented fix is `with-all-grammars`, which is 280 grammars and
    # 233 MiB — a fifth of everything this file adds, to carry things like
    # tree-sitter-lean (17 MiB) and tree-sitter-verilog (17 MiB). The list below
    # is instead derived from the `set-tree-sitter!` calls in the modules
    # actually enabled above, so it is exactly the set that can ever be loaded:
    # ~13 MiB. Adding a `+tree-sitter` language means adding its grammar here.
    extraPackages = epkgs: [
      (epkgs.treesit-grammars.with-grammars (g: with g; [
        tree-sitter-bash
        tree-sitter-c # :lang cc
        tree-sitter-cmake
        tree-sitter-cpp
        tree-sitter-dockerfile # :tools docker
        tree-sitter-go # :lang go
        tree-sitter-gomod
        tree-sitter-gowork
        tree-sitter-javascript # :lang javascript
        tree-sitter-jsdoc
        tree-sitter-json # :lang json
        tree-sitter-lua # :lang lua
        tree-sitter-markdown # :lang markdown
        tree-sitter-markdown-inline
        tree-sitter-nix # :lang nix
        tree-sitter-python # :lang python
        tree-sitter-rust # :lang rust
        tree-sitter-toml # remapped by :tools tree-sitter itself
        tree-sitter-tsx
        tree-sitter-typescript
        tree-sitter-yaml # :lang yaml
      ]))
    ];
  };

  # Run Emacs as a daemon. This is the answer to Doom's startup cost: the
  # several seconds are paid once at login, and `emacsclient` then opens
  # instantly. Without it Doom feels slow next to LazyVim's ~185ms.
  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = false; # EDITOR is contested already; see ../host.nix notes
  };
}
