# A HiFiBerryOS music player. Everything below is optional except
# `hifiberry.enable`; see the README for all options.
{ ... }:
{
  hifiberry.enable = true;

  # Your HiFiBerry card's device tree overlay. Left unset, the card is
  # detected on the first boot, which then reboots once.
  # hifiberry.soundcard = "hifiberry-dacplus-std"; # DAC+ / Amp2

  # Players: Music Assistant (Sendspin) and Bluetooth are on by default.
  # hifiberry.players.shairport.enable = true; # AirPlay
  # hifiberry.players.librespot.enable = true; # Spotify Connect

  # Answer the web interface's setup wizard here instead.
  # hifiberry.setup = {
  #   skipWizard = true;
  #   systemName = "Living room"; # hostname living-room(.local)
  # };

  # SSH accepts the initial password (hifiberry) until you add a key.
  # users.users.hifiberry.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA… you@laptop" ];

  # time.timeZone = "Europe/Paris";

  system.stateVersion = "26.05";
}
