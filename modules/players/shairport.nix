{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.shairport;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."shairport.json" = "${hb.shairport}/etc/audiocontrol/players.d/shairport.json";
      configserverConfD."shairport.json" = pkgs.writeText "shairport.json" (
        builtins.toJSON { systemd.shairport = "all"; }
      );
      sharePackages = [ hb.shairport ];
      defaultEnabledUserServices = lib.optional p.autoStart "shairport";
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-shairport";
          name = "AirPlay";
          icon = "/images/svg/airplay.svg";
          description = "AirPlay receiver (shairport-sync)";
          version = hb.shairport.version;
        })
      ];
    };

    environment.systemPackages = [ hb.shairport ];

    # /etc/shairport-sync.conf is the admin's copy; start-shairport derives the
    # runtime config from it.
    environment.etc."shairport-sync.conf".source =
      "${hb.shairport}/share/hifiberry-shairport/shairport-sync.conf.default";

    # AirPlay 2 needs the shared PTP clock daemon as a system service.
    systemd.services.nqptp = {
      description = "NQPTP daemon for network clock synchronization";
      documentation = [ "https://github.com/mikebrady/nqptp" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${hb.shairport}/bin/start-nqptp";
        DynamicUser = true;
        LimitRTPRIO = 6;
        Restart = "on-failure";
        RestartSec = 5;
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      };
    };

    # shairport-sync's D-Bus and MPRIS interfaces on the system bus.
    services.dbus.packages = [ hb.shairport.airplay2 ];

    systemd.user.units."shairport.service".text = hifiberryLib.mkPlayerUnit {
      description = "Shairport Sync - AirPlay Audio Receiver";
      execStart = "${hb.shairport}/bin/start-shairport";
      after = [ "nqptp.service" ];
      wants = [ "nqptp.service" ];
      restartSec = 2;
      extraUnit.Documentation = "man:shairport-sync(1) https://github.com/mikebrady/shairport-sync";
    };
  };
}
