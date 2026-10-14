# Bluetooth audio: BlueZ, the WirePlumber bluez monitor in the headless
# session, and hifiberry-bluetooth (pairing agent, API on 1082).
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
  config = lib.mkIf (cfg.enable && cfg.bluetooth.enable) {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    hifiberry.internal = {
      nginxSnippets = [
        "${hb.hifiberry-bluetooth}/share/hifiberry-bluetooth/nginx/hifiberry-btaudio.nginx"
      ];
      acrPlayers."bluetooth.json" = "${hb.hifiberry-bluetooth}/etc/audiocontrol/players.d/bluetooth.json";
      configserverConfD."hifiberry-bluetooth.json" = pkgs.writeText "hifiberry-bluetooth.json" (
        builtins.toJSON { systemd.hifiberry-bluetooth = "all"; }
      );
    };

    systemd.services.hifiberry-bluetooth = {
      description = "Hifiberry Bluetooth";
      wantedBy = [ "multi-user.target" ];
      requires = [ "bluetooth.service" ];
      after = [ "bluetooth.service" ];
      path = [ pkgs.util-linux ];
      serviceConfig = {
        ExecStartPre = "-${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        ExecStart = "${hb.hifiberry-bluetooth}/bin/hifiberry-bluetooth";
        Restart = "on-failure";
        RestartSec = 5;
        User = "root";
      };
    };
  };
}
