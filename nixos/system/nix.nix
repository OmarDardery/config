{ ... }:
{
  # ── Nix ────────────────────────────────────────────────────────────────
  nix = {
    settings = {
      # Keep parallel native builds from exhausting this laptop's 14 GiB RAM.
      max-jobs = 2;
      cores = 4;

      # Collect unreferenced store paths when a build is running low on space.
      min-free = 1024 * 1024 * 1024;
      max-free = 5 * 1024 * 1024 * 1024;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Prebuilt noctalia, so it isn't compiled from source on every update.
      # Only works because the noctalia input does not follow our nixpkgs.
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };

  # Let interactive work take priority over scheduled store maintenance.
  systemd.services.nix-gc.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
  };
  systemd.services.nix-optimise.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
  };

  # Proprietary drivers are native; user-only insecure app exceptions stay in HM.
  nixpkgs.config.allowUnfree = true;
}
