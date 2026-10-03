{ pkgs, profile, ... }:
{
  # Only the privileged capture helper and access group are host-owned.
  users.groups.wireshark = { };
  security.wrappers.dumpcap = {
    source = "${pkgs.wireshark-cli}/bin/dumpcap";
    capabilities = "cap_net_raw,cap_net_admin+eip";
    owner = "root";
    group = "wireshark";
    permissions = "u+rx,g+x";
  };

  users.users.${profile.username}.extraGroups = [ "wireshark" ];

}
