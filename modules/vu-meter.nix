# VU meter: real-time levels from PipeWire over WebSocket (port 2717).
{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && cfg.vuMeter.enable) {
    hifiberry.internal = {
      nginxSnippets = [ "${hb.vu-meter}/share/hifiberry-vu-meter/nginx/hifiberry-vu-meter.nginx" ];
      authManifests."vu-meter.json" = "${hb.vu-meter}/share/hifiberry/auth.d/vu-meter.json";
      defaultEnabledUserServices = [ "vu-meter" ];
    };

    systemd.user.units."vu-meter.service".text = hifiberryLib.renderUnit {
      Unit = {
        Description = "HiFiBerry VU Meter Service";
        After = "pipewire.service";
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${hb.vu-meter}/bin/vu-meter-service";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = "default.target";
    };
  };
}
