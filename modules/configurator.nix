# hifiberry-configurator: config-server (port 1081), sound card detection,
# volume store/restore, Samba mounts and the player registry.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
  configurator = hb.configurator;

  toolPath = [
    configurator
    hb.hateeprom
    pkgs.systemd
    pkgs.util-linux
    pkgs.coreutils
    pkgs.alsa-utils
    pkgs.i2c-tools
    pkgs.cifs-utils
    pkgs.samba
    pkgs.networkmanager
    pkgs.iproute2
    pkgs.nettools
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.raspberrypi-eeprom
    pkgs.libgpiod
    pkgs.bash
    pkgs.gnugrep
    pkgs.gawk
    pkgs.gnused
    pkgs.procps
    "/run/current-system/sw"
    "/run/wrappers"
  ]
  # vcgencmd & co., from nixos-raspberrypi's overlay (absent in the test VM)
  ++ lib.optional (pkgs ? raspberrypi-utils) pkgs.raspberrypi-utils;

  detectArgs = if cfg.soundcard == null then "--store --reboot" else "";
in
{
  config = lib.mkIf cfg.enable {
    hifiberry.internal = {
      nginxSnippets = [ "${configurator}/share/hifiberry-configurator/nginx/hifiberry-config.nginx" ];
      authManifests."config.json" = "${configurator}/share/hifiberry/auth.d/config.json";
    };

    environment.etc = {
      "configserver/configserver.json".source =
        "${configurator}/share/hifiberry-configurator/configserver.json";
      "hifiberry/nixos-extensions.json".text = builtins.toJSON cfg.internal.extensions;
    }
    // lib.mapAttrs' (
      name: path: lib.nameValuePair "configserver/conf.d/${name}" { source = path; }
    ) cfg.internal.configserverConfD
    // lib.mapAttrs' (
      name: path: lib.nameValuePair "hifiberry/auth.d/${name}" { source = path; }
    ) cfg.internal.authManifests;

    systemd.tmpfiles.rules = [
      "d /etc/hifiberry/players.d 0755 root root -"
      "d /etc/hifiberry/players.d/icons 0755 root root -"
      "d /etc/hifiberry/features.d 0755 root root -"
      "d /var/log/hifiberry 0755 root root -"
    ];

    systemd.services.config-detect = {
      description = "HiFiBerry Sound Card Detection and Configuration";
      documentation = [ "man:config-detect(1)" ];
      wantedBy = [ "multi-user.target" ];
      after = [
        "sigmatcpserver.service"
        "systemd-modules-load.service"
        "systemd-udev-settle.service"
        "hifiberry-firmware-config.service"
      ];
      wants = [
        "sigmatcpserver.service"
        "systemd-udev-settle.service"
      ];
      before = [ "config-server.service" ];
      path = toolPath;
      unitConfig.RequiresMountsFor = "/boot/firmware";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${configurator}/bin/config-detect ${detectArgs} --logfile /var/log/hifiberry-detect.log";
        RemainAfterExit = true;
        TimeoutStartSec = 60;
      };
    };

    systemd.services.config-server = {
      description = "HiFiBerry Configuration Server";
      documentation = [ "man:config-server(1)" ];
      wantedBy = [ "multi-user.target" ];
      wants = [
        "network-online.target"
        "config-detect.service"
      ];
      after = [
        "network-online.target"
        "systemd-modules-load.service"
        "config-detect.service"
        "create-uuid.service"
      ];
      startLimitIntervalSec = 30;
      startLimitBurst = 3;
      path = toolPath;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${configurator}/bin/config-server --host 127.0.0.1 --port 1081 --verbose --auto-restore-settings";
        Restart = "always";
        RestartSec = 5;
        User = "root";
        Group = "audio";
        PrivateMounts = false;
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/0"
          "PIPEWIRE_RUNTIME_DIR=/run/pipewire"
        ];
        LimitNOFILE = 1024;
        LimitNPROC = 64;
      };
    };

    systemd.services.volume-restore = {
      description = "HiFiBerry Volume Restore Service";
      documentation = [ "man:config-volume(1)" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "sound.target" ];
      requires = [ "sound.target" ];
      path = toolPath;
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/sleep 2"
          "${configurator}/bin/config-soundcard --get-or-create-volume-control Softvol"
        ];
        ExecStart = "${configurator}/bin/config-volume --restore";
        TimeoutStartSec = 10;
        RemainAfterExit = true;
      };
    };

    systemd.services.volume-store = {
      description = "Store current volume settings to configuration database";
      after = [
        "sound.target"
        "network.target"
        "local-fs.target"
      ];
      path = toolPath;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${configurator}/bin/config-volume --store";
        TimeoutStartSec = 10;
      };
    };
    systemd.timers.volume-store = {
      description = "Run volume-store service every minute";
      wantedBy = [ "timers.target" ];
      after = [ "sound.target" ];
      timerConfig = {
        Unit = "volume-store.service";
        OnBootSec = 60;
        OnUnitActiveSec = 60;
        AccuracySec = 1;
        RandomizedDelaySec = 5;
      };
    };

    systemd.services.sambamount = {
      description = "Mount Samba/CIFS shares";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = toolPath;
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "-${pkgs.coreutils}/bin/rm -f /tmp/sambamount_state.json";
        ExecStart = "${configurator}/bin/config-sambamount --mount-all --verbose";
        ExecStop = "${pkgs.bash}/bin/bash -c 'for mp in $(${configurator}/bin/config-sambamount --list-mounted-dirs); do umount \"$mp\" 2>/dev/null || true; done'";
        RemainAfterExit = true;
        PrivateMounts = false;
        RestartSec = 5;
      };
    };

    systemd.services.ble-provisioning = lib.mkIf cfg.bleProvisioning.enable {
      description = "HiFiBerry BLE WiFi Provisioning";
      wantedBy = [ "multi-user.target" ];
      after = [
        "bluetooth.target"
        "NetworkManager.service"
      ];
      wants = [ "bluetooth.target" ];
      path = toolPath;
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${configurator}/bin/config-ble-provision --check-network";
        ExecStart = "${configurator}/bin/config-ble-provision --serve";
        Restart = "on-failure";
        RestartSec = 30;
      };
    };
  };
}
