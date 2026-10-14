{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.squeezelite;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."squeezelite.json" = "${hb.squeezelite}/etc/audiocontrol/players.d/squeezelite.json";
      configserverConfD."squeezelite.json" = pkgs.writeText "squeezelite.json" (
        builtins.toJSON { systemd.squeezelite = "all"; }
      );
      sharePackages = [ hb.squeezelite ];
      defaultEnabledUserServices = lib.optional p.autoStart "squeezelite";
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-squeezelite";
          name = "LMS (Squeezebox)";
          icon = "/images/svg/squeezelite.svg";
          description = "Squeezelite - Lightweight Squeezebox player for HiFiBerry";
          version = hb.squeezelite.version;
        })
      ];
    };

    environment.systemPackages = [ hb.squeezelite ];

    systemd.user.units."squeezelite.service".text = hifiberryLib.mkPlayerUnit {
      description = "Squeezelite";
      execStart = "${hb.squeezelite}/bin/start-squeezelite";
      wants = [ "network.target" ];
      execStartPre = [ "-${hb.configurator}/bin/config-volume --store" ];
      execStartPost = [
        "${pkgs.coreutils}/bin/sleep 2"
        "-${hb.configurator}/bin/config-volume --restore"
      ];
      extraService.TimeoutStopSec = 5;
    };
  };
}
