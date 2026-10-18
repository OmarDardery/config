{
  pkgs,
  config,
  ...
}:
let
  thunar = pkgs.thunar.override {
    thunarPlugins = [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman
    ];
  };
  desktopApps = with pkgs; [
    thunar
    (papers.override { supportNautilus = false; })
    file-roller
    gnome-calculator
    gnome-disk-utility
    gnome-control-center
    seahorse
  ];
  desktopServices =
    desktopApps
    ++ (with pkgs; [
      gvfs
      tumbler
      xfconf
    ]);
in
{
  home.packages = desktopServices ++ [
    pkgs.sshfs
    pkgs.xdg-utils
    pkgs.zenity
    pkgs.system-config-printer
  ];
  dbus.packages = desktopServices;
  systemd.user.packages = desktopServices;
  home.sessionSearchVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];
  home.sessionSearchVariables.XDG_DATA_DIRS = [
    "${config.home.profileDirectory}/share"
  ]
  ++ map (package: "${package}/share/gsettings-schemas/${package.name}") desktopApps;
  home.sessionVariables.SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

  programs.bash.enableVteIntegration = true;
  programs.zsh.enableVteIntegration = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
  xfconf = {
    settings = {
      thunar.misc-volume-management = true;
      thunar-volman = {
        "automount-drives/enabled" = true;
        "automount-media/enabled" = true;
        "autobrowse/enabled" = true;
      };
    };
  };

  # Index documents without traversing generated build and dependency trees.
  dconf.settings."org/freedesktop/tracker/miner/files".ignored-directories = [
    "po"
    "CVS"
    "core-dumps"
    "lost+found"
    "node_modules"
    "target"
    "build"
    "dist"
  ];
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/html" = [ "zen.desktop" ];
      "application/xhtml+xml" = [ "zen.desktop" ];
      "x-scheme-handler/http" = [ "zen.desktop" ];
      "x-scheme-handler/https" = [ "zen.desktop" ];
      "application/pdf" = [ "org.gnome.Papers.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "text/plain" = [ "codium.desktop" ];
    };
  };
}
