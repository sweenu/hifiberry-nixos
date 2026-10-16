{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.sendspin;
  hb = cfg.packages;
  # hifiberry.players.sendspin.protocol picks which sendspin-cpp is built.
  sendspin = if p.protocol == "v1" then hb.sendspin-v1 else hb.sendspin;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."sendspin.json" = "${sendspin}/etc/audiocontrol/players.d/sendspin.json";
      configserverConfD."sendspin.json" = "${sendspin}/etc/configserver/conf.d/sendspin.json";
      sharePackages = [ sendspin ];
      defaultEnabledUserServices = lib.optional p.autoStart "sendspin";
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-sendspin";
          name = "Music Assistant";
          icon = "/images/svg/sendspin.svg";
          description = "Sendspin player for HiFiBerryOS";
          version = sendspin.version;
        })
      ];
    };

    environment.systemPackages = [ sendspin ];

    systemd.user.units."sendspin.service".text = hifiberryLib.mkPlayerUnit {
      description = "Sendspin Player (Music Assistant)";
      execStart = "${pkgs.writeShellScript "start-sendspin-wrapped" ''
        export PATH=${
          lib.makeBinPath [
            hb.configurator
            pkgs.systemd
            pkgs.nettools
            pkgs.coreutils
          ]
        }:$PATH
        # start-sendspin exits successfully, and for good, when it finds no sound
        # card; at boot the card can still be coming up, so give it a minute.
        for _ in $(seq 1 20); do
          config-soundcard --detected >/dev/null 2>&1 && break
          sleep 3
        done
        exec ${sendspin}/bin/start-sendspin "$@"
      ''}";
      wants = [ "avahi-daemon.service" ];
      restartSec = 2;
    };
  };
}
