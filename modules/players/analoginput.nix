{
  config,
  lib,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.analoginput;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      configserverConfD."analoginput.json" = builtins.toFile "analoginput.json" (
        builtins.toJSON { systemd.analoginput = "all"; }
      );
      defaultEnabledUserServices = lib.optional p.autoStart "analoginput";
    };

    environment.systemPackages = [ hb.analoginput ];

    systemd.user.units."analoginput.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry Analog Input Service";
      type = "oneshot";
      remainAfterExit = true;
      restart = "no";
      execStart = "${hb.analoginput}/bin/hifiberry-analoginput connect";
      execStop = "${hb.analoginput}/bin/hifiberry-analoginput disconnect";
    };
  };
}
