{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.raat;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isAarch64;
        message = "hifiberry.players.raat: the RAAT binaries HiFiBerry publishes exist for aarch64 only.";
      }
    ];

    # The RAAT SDK is proprietary; the binaries come from HiFiBerry's package.
    nixpkgs.config.allowUnfreePredicate = lib.mkDefault (
      pkg: builtins.elem (lib.getName pkg) [ "hifiberry-raat" ]
    );

    hifiberry.internal = {
      acrPlayers."raat.json" = "${hb.raat}/etc/audiocontrol/players.d/raat.json";
      defaultEnabledUserServices = lib.optional p.autoStart "raat";
    };

    environment.systemPackages = [ hb.raat ];

    # The metadata and control pipes live in /var/lib/raat, writable by the player.
    systemd.tmpfiles.rules = [ "d /var/lib/raat 0775 ${cfg.user} audio -" ];

    systemd.user.units."raat.service".text = hifiberryLib.mkPlayerUnit {
      description = "Roon";
      execStart = "${hb.raat}/bin/start-raat";
      wants = [ "sound.target" ];
      conditionPathExists = "/etc/uuid";
      extraService = {
        TimeoutStopSec = 10;
        SyslogIdentifier = "raat";
      };
    };
  };
}
