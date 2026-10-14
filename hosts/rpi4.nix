# HiFiBerryOS on a Raspberry Pi 4.
{ nixos-raspberrypi, ... }:
{
  imports = [
    ./common.nix
    nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
  ];

  networking.hostName = "hifiberry";
  system.nixos.tags = [ "raspberry-pi-4" ];
}
