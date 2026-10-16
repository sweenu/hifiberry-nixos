# Ports for the web interface and the enabled players (hifiberry.openFirewall).
{ config, lib, ... }:
let
  cfg = config.hifiberry;
  inherit (cfg) players;
  # These negotiate ports at runtime (AirPlay 2 streams, the Spotify Connect
  # zeroconf endpoint, Roon's RAAT, Squeezelite's discovery replies, AES67).
  dynamicPorts = lib.any (name: players.${name}.enable) [
    "shairport"
    "librespot"
    "raat"
    "squeezelite"
    "aes67"
  ];
  ephemeral = {
    from = 32768;
    to = 60999;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.openFirewall) {
    networking.firewall = {
      allowedTCPPorts = [
        80 # web interface (nginx)
      ]
      ++ lib.optional players.sendspin.enable 8928
      ++ lib.optional players.mpd.enable 6600
      ++ lib.optional players.shairport.enable 7000
      ++ lib.optional players.squeezelite.enable 3483;
      allowedUDPPorts =
        # PTP, for AirPlay 2 (nqptp) and AES67
        lib.optionals (players.shairport.enable || players.aes67.enable) [
          319
          320
        ]
        ++ lib.optional players.raat.enable 9003
        ++ lib.optional players.squeezelite.enable 3483;
      allowedTCPPortRanges = lib.optional dynamicPorts ephemeral;
      allowedUDPPortRanges = lib.optional dynamicPorts ephemeral;
    };
  };
}
