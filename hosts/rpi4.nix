# HiFiBerryOS on a Raspberry Pi 4.
{ nixos-raspberrypi, ... }:
{
  imports = [
    ./common.nix
    nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
  ];

  # HiFiBerry DAC+ / Amp2. Declaring the card puts its overlay in config.txt,
  # so the first boot needs no detection and no reboot. This is the overlay
  # hifiberry-configurator picks for this card ("DAC+/Amp2").
  hifiberry.soundcard = "hifiberry-dacplus-std";
  system.nixos.tags = [ "raspberry-pi-4" ];
}
