# HiFiBerryOS on a Raspberry Pi 5.
{ nixos-raspberrypi, ... }:
{
  imports = [
    ./common.nix
    nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
  ];

  networking.hostName = "hifiberry";
  system.nixos.tags = [ "raspberry-pi-5" ];
}
