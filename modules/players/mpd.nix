{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.mpd;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."mpd.json" = "${hb.mpd}/etc/audiocontrol/players.d/mpd.json";
      defaultEnabledUserServices = lib.optional p.autoStart "mpd";
    };

    environment.systemPackages = [ hb.mpd ];

    # /var/lib/mpd, group audio and group writable, as the package's postinst.
    systemd.tmpfiles.rules = [
      "d /var/lib/mpd 2775 root audio -"
      "d /var/lib/mpd/music 2775 root audio -"
      "d /var/lib/mpd/playlists 2775 root audio -"
    ];

    systemd.user.units."mpd.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry Music Player Daemon (user)";
      execStart = "${hb.mpd}/bin/start-mpd";
      wants = [ "network.target" ];
      restartSec = 10;
      extraUnit.Documentation = "https://www.musicpd.org/";
    };

    systemd.services.hifiberry-mpd-reconcile = {
      description = "Reconcile MPD music links after SMB changes";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      path = [
        pkgs.util-linux
        hb.mpd
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${hb.mpd}/bin/mpd-reconcile";
      };
    };
  };
}
