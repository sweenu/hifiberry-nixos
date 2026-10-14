# HiFiBerryOS on a Raspberry Pi Zero 2.
{ nixos-raspberrypi, ... }:
{
  imports = [
    ./common.nix
    nixos-raspberrypi.nixosModules.raspberry-pi-02.base
    nixos-raspberrypi.nixosModules.raspberry-pi-02.bluetooth
  ];

  networking.hostName = "hifiberry";
  system.nixos.tags = [ "raspberry-pi-02" ];
}
