# DSP toolkit: sigmatcpserver (REST API on 13141) for the HiFiBerry DSP boards,
# started when /dev/spidev0.0 appears, and the DSP profiles.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && cfg.dsp.enable) {
    hifiberry.internal = {
      nginxSnippets = [ "${hb.hifiberry-dsp}/share/hifiberry-dsp/nginx/hifiberry-sigmatcp.nginx" ];
      authManifests."dsptoolkit.json" = "${hb.hifiberry-dsp}/share/hifiberry/auth.d/dsptoolkit.json";
    };

    services.udev.packages = [ hb.hifiberry-dsp ];

    systemd.tmpfiles.rules = [
      "d /var/lib/hifiberry 0755 root root -"
      "d /var/lib/hifiberry/speaker-presets 0755 root root -"
    ];

    systemd.services.sigmatcpserver = {
      description = "HiFiBerry DSP TCP/REST API service";
      wantedBy = [ "dev-spidev0.0.device" ];
      after = [
        "dev-spidev0.0.device"
        "network.target"
      ];
      unitConfig.ConditionPathExists = "/dev/spidev0.0";
      path = [
        pkgs.alsa-utils
        hb.configurator
      ];
      serviceConfig = {
        ExecStart = "${hb.hifiberry-dsp}/bin/sigmatcpserver --localhost --enable-rest --alsa --disable-tcp --store --restore";
        KillSignal = "SIGINT";
        TimeoutStopSec = 15;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
