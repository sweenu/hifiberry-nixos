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

    # BlueZ 5 dropped main.conf's Class option and derives the class of device
    # from the chassis type hostnamed reports instead. A Raspberry Pi has no
    # DMI chassis, so the major class stays 0 ("Miscellaneous") and phones show
    # a generic icon when pairing; no chassis value maps to a speaker either.
    # Set Audio/Video (4) and Loudspeaker (20, the minor class already shifted
    # into bits 2-7) over mgmt, which btmgmt reads as decimal. The kernel keeps
    # the service class bits it derives from the registered profiles. The class
    # resets whenever bluetoothd restarts, hence PartOf.
    systemd.services.hifiberry-bluetooth-class = {
      description = "Announce the Bluetooth adapter as a loudspeaker";
      wantedBy = [ "multi-user.target" ];
      requires = [ "bluetooth.service" ];
      after = [ "bluetooth.service" ];
      partOf = [ "bluetooth.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.hardware.bluetooth.package}/bin/btmgmt class 4 20";
      };
    };
  };
}
