{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    jq
    file
    rsync
    zip
    unzip
    _7zz
  ];
}
