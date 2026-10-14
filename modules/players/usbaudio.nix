{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.usbaudio;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."usbaudio.json" = "${hb.usbaudio}/etc/audiocontrol/players.d/usbaudio.json";
      configserverConfD."usbaudio.json" = "${hb.usbaudio}/etc/configserver/conf.d/usbaudio.json";
      sharePackages = [ hb.usbaudio ];
      defaultEnabledUserServices = lib.optionals p.autoStart [
        "usbaudio"
        "usbaudio-state"
      ];
    };

    environment.systemPackages = [ hb.usbaudio ];

    # USB device mode: dwc2 in peripheral mode (config-configtxt --enable-usb-gadget).
    hardware.raspberry-pi.config.all.dt-overlays.dwc2 = {
      enable = true;
      params.dr_mode = {
        enable = true;
        value = "peripheral";
      };
    };

    systemd.services.hifiberry-usbgadget = {
      description = "HiFiBerry USB Audio Gadget (UAC2)";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      unitConfig = {
        DefaultDependencies = false;
        ConditionPathExistsGlob = "/sys/class/udc/*";
      };
      path = [ pkgs.kmod ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.kmod}/bin/modprobe libcomposite";
        ExecStart = "${hb.usbaudio}/bin/hifiberry-usbgadget create";
        ExecStop = "${hb.usbaudio}/bin/hifiberry-usbgadget remove";
      };
    };

    systemd.user.units."usbaudio.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry USB Audio Input Service";
      type = "oneshot";
      remainAfterExit = true;
      restart = "no";
      execStart = "${hb.usbaudio}/bin/hifiberry-usbaudio connect";
      execStop = "${hb.usbaudio}/bin/hifiberry-usbaudio disconnect";
    };
    systemd.user.units."usbaudio-state.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry USB Audio Gadget State Reporter (ACR)";
      execStart = "${hb.usbaudio}/bin/hifiberry-usbaudio state --card UAC2Gadget";
    };
  };
}
