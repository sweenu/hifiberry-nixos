# Bluetooth audio: BlueZ, the WirePlumber bluez monitor in the headless
# session, and hifiberry-bluetooth (the pairing agent).
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
      # No btaudio nginx snippet: it proxies /api/btaudio/ and /btaudio/ to
      # localhost:1082, but hifiberry-bluetooth is only a D-Bus agent and
      # serves nothing. The web interface never calls either location.
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
