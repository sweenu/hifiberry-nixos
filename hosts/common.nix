# Shared configuration of the example HiFiBerryOS hosts.
{ lib, ... }:
{
  hifiberry.enable = true;

  # Music Assistant (Sendspin) and Bluetooth are on by default; enable other
  # players with hifiberry.players.<name>.enable = true.
  hifiberry.players.sendspin.enable = true;

  # A Sendspin receiver: leave out what it does not use.
  hifiberry.roomeq.enable = false; # room measurement and correction
  hifiberry.dsp.enable = false; # only for HiFiBerry DSP boards
  hifiberry.bleProvisioning.enable = false; # Wi-Fi setup over Bluetooth LE

  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Headless appliance: no documentation, small closure.
  documentation.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
}
