{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.analogRecognition;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."analog.json" = "${hb.analog-recognition}/etc/audiocontrol/players.d/analog.json";
      configserverConfD."analog-recognition.json" = pkgs.writeText "analog-recognition.json" (
        builtins.toJSON { systemd.analog-recognition = "all"; }
      );
      sharePackages = [ hb.analog-recognition ];
      defaultEnabledUserServices = lib.optional p.autoStart "analog-recognition";
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-analog-recognition";
          name = "Analog Input";
          icon = "/images/svg/input.svg";
          description = "HiFiBerry analog input recognition service";
          version = hb.analog-recognition.version;
        })
      ];
    };

    environment.systemPackages = [
      hb.analog-recognition
      pkgs.songrec
    ];
    environment.etc."analog-recognition/config.toml".source =
      "${hb.analog-recognition}/etc/analog-recognition/config.toml";

    systemd.user.units."analog-recognition.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry Analog Input Recognition";
      execStart = "${hb.analog-recognition}/bin/analog-recognition";
      after = [ "vu-meter.service" ];
      partOf = [ "pipewire.service" ];
      execCondition = "${hb.configurator}/bin/config-soundcard --has-input";
      execStartPre = [ "${pkgs.coreutils}/bin/sleep 2" ];
    };
  };
}
