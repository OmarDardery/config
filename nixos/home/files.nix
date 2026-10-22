{ isNixOS, ... }:
let
  browser = if isNixOS then "zen.desktop" else "config-browser.desktop";
in
{
  home.file.".local/bin/desktop-browser" = {
    enable = !isNixOS;
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      if command -v firefox-esr >/dev/null; then
        exec firefox-esr "$@"
      fi
      exec firefox "$@"
    '';
  };
  xdg.dataFile."applications/config-browser.desktop" = {
    enable = !isNixOS;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Firefox
      Exec=desktop-browser %u
      Terminal=false
      NoDisplay=true
      MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
    '';
  };
  xdg.userDirs = {
    enable = true;
    package = null;
    createDirectories = true;
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "text/html" = [ browser ];
      "application/xhtml+xml" = [ browser ];
      "x-scheme-handler/http" = [ browser ];
      "x-scheme-handler/https" = [ browser ];
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
