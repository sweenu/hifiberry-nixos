{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.librespot;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."librespot.json" = "${hb.librespot}/etc/audiocontrol/players.d/librespot.json";
      configserverConfD."librespot.json" = pkgs.writeText "librespot.json" (
        builtins.toJSON { systemd.librespot = "all"; }
      );
      sharePackages = [ hb.librespot ];
      defaultEnabledUserServices = lib.optional p.autoStart "librespot";
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-librespot";
          name = "Spotify (librespot)";
          icon = "/images/svg/spotify.svg";
          description = "Librespot Spotify Connect player (HiFiBerry build)";
          version = hb.librespot.version;
        })
      ];
    };

    environment.systemPackages = [ hb.librespot ];

    systemd.user.units."librespot.service".text = hifiberryLib.mkPlayerUnit {
      description = "Librespot Spotify Connect Player (user service)";
      execStart = "${hb.librespot}/bin/start-librespot";
      environment = [ "RUST_BACKTRACE=1" ];
      restartSec = 10;
      extraService = {
        StartLimitInterval = 30;
        StartLimitBurst = 5;
      };
    };
  };
}
