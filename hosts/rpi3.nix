# HiFiBerryOS on a Raspberry Pi 3.
{ nixos-raspberrypi, ... }:
{
  imports = [
    ./common.nix
    nixos-raspberrypi.nixosModules.raspberry-pi-3.base
  ];

  system.nixos.tags = [ "raspberry-pi-3" ];
}
