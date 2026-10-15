# HiFiBerryOS for NixOS. Import this module and set `hifiberry.enable = true`
# on a Raspberry Pi configuration (see templates/default for a complete one).
{ lib, ... }:
{
  imports = [
    ./options.nix
    ./base.nix
    ./boot.nix
    ./pipewire.nix
    ./audiocontrol.nix
    ./configurator.nix
    ./webui.nix
    ./dsp.nix
    ./bluetooth.nix
    ./vu-meter.nix
    ./roomeq.nix
    ./players/default.nix
    ./webmcp.nix
    ./wifi-setup.nix
    ./setup.nix
    ./firewall.nix
  ];

  meta.maintainers = [ ];
  _module.args.hifiberryLib = import ./lib.nix { inherit lib; };
}
