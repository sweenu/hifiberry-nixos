# Shared configuration of the example HiFiBerryOS hosts.
{ lib, ... }:
{
  hifiberry.enable = true;

  # HiFiBerryOS defaults: every player available, Music Assistant included.
  hifiberry.players.sendspin.enable = true;

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
