{
  pkgs,
  lib,
  config,
  profile,
  isLaptop,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      nwg-displays
      wlr-randr
      wl-mirror
    ]
    ++ lib.optionals isLaptop [
      (pkgs.writeShellApplication {
        name = "mirror-laptop";
        runtimeInputs = [
          config.programs.umbriel.package
          pkgs.jq
          pkgs.wl-mirror
        ];
        text = ''
          outputs=$(umbriel outputs --json)
          panel=$(jq -er '
            [.[] | select(.make == "BOE" and .model == "NE140QDM-NX7" and .enabled) | .name]
            | if length == 1 then .[0] else error("Expected one active laptop panel") end
          ' <<< "$outputs")
          if ! jq -e 'any(.[]; .name == "HDMI-A-1" and .enabled)' <<< "$outputs" >/dev/null; then
            printf '%s\n' 'HDMI-A-1 is not active; connect and enable the projector first.' >&2
            exit 1
          fi
          exec wl-mirror --fullscreen-output HDMI-A-1 "$panel"
        '';
      })
    ];
}
