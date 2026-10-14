# Shared configuration of the example HiFiBerryOS hosts.
{ lib, ... }:
{
  hifiberry.enable = true;

  # Music Assistant (Sendspin) and Bluetooth are on by default; enable other
  # players with hifiberry.players.<name>.enable = true.
  hifiberry.players.sendspin.enable = true;

  # SSH with this key only: the default password is public (it is in the
  # published image), so SSH does not accept passwords at all.
  users.users.hifiberry.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGyqgAJe9NTMN895kztljIIPYIRExKOdDvB6zroete6Z sweenu@carokann"
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };

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
  # CI pushes everything it builds here, so updating the Pi downloads the
  # HiFiBerry packages instead of compiling them on the Pi.
  nix.settings.substituters = [ "https://sweenu.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "sweenu.cachix.org-1:DvQl16NWBp41k5IlxTODTOrIThyGRj8/ekrXxEheBQ0="
  ];
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
}
