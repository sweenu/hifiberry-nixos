# The base system: the player user, the directories HiFiBerryOS expects, mDNS,
# networking, and the command line tools.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;

  # /usr/share/hifiberry as HiFiBerryOS' components expect it: players.d,
  # features.d, dspprofiles, speaker-presets, signals, ... all merged.
  shareEnv = pkgs.buildEnv {
    name = "hifiberry-share";
    paths = cfg.internal.sharePackages;
    pathsToLink = [ "/share/hifiberry" ];
  };
in
{
  config = lib.mkIf cfg.enable {
    hifiberry.internal.sharePackages = [
      hb.configurator
      hb.webui
      hb.dspprofiles
    ];

    users.users.${cfg.user} = {
      isNormalUser = true;
      uid = cfg.uid;
      description = "HiFiBerry player user";
      linger = true;
      initialPassword = lib.mkIf (cfg.initialPassword != null) cfg.initialPassword;
      # The groups install-all gives the player user on Raspberry Pi OS.
      extraGroups = [
        "audio"
        "video"
        "render"
        "input"
        "gpio"
        "i2c"
        "spi"
        "plugdev"
        "lp"
        "networkmanager"
        "wheel"
      ];
    };
    users.groups = {
      gpio = { };
      i2c = { };
      spi = { };
      plugdev = { };
    };

    environment.etc."hifiberry.user".text = cfg.user + "\n";

    # User managers log to the journal, as install-all configures.
    systemd.user.extraConfig = ''
      DefaultStandardOutput=journal
      DefaultStandardError=journal
    '';

    systemd.tmpfiles.rules = [
      "d /usr/share 0755 root root -"
      "L+ /usr/share/hifiberry - - - - ${shareEnv}/share/hifiberry"
      "d /var/hifiberry 0755 root root -"
      "d /var/lib/hifiberry 0755 root root -"
      "d /var/lib/hifiberry/player-defaults 0755 root root -"
    ];

    # First boot: enable the player services HiFiBerryOS enables when a player
    # package is installed. Afterwards the web interface owns the state, in the
    # player user's own systemd configuration.
    systemd.services.hifiberry-player-defaults = {
      description = "Enable HiFiBerryOS player services on first boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      before = [
        "systemd-logind.service"
        "user@${toString cfg.uid}.service"
      ];
      unitConfig.RequiresMountsFor = "/home/${cfg.user}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        home=$(${pkgs.getent}/bin/getent passwd ${cfg.user} | cut -d: -f6)
        wants="$home/.config/systemd/user/default.target.wants"
        for svc in ${lib.escapeShellArgs cfg.internal.defaultEnabledUserServices}; do
          marker="/var/lib/hifiberry/player-defaults/$svc"
          [ -e "$marker" ] && continue
          install -d -o ${cfg.user} -g users "$home/.config" "$home/.config/systemd" "$home/.config/systemd/user" "$wants"
          ln -sfn "/etc/systemd/user/$svc.service" "$wants/$svc.service"
          chown -h ${cfg.user}:users "$wants/$svc.service"
          touch "$marker"
        done
      '';
    };

    # The system UUID, as hifiberry-configurator's create-uuid.service.
    systemd.services.create-uuid = {
      description = "Create system UUID file";
      wantedBy = [ "multi-user.target" ];
      before = [ "config-server.service" ];
      unitConfig.ConditionPathExists = "!/etc/uuid";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/sh -c '${pkgs.util-linux}/bin/uuidgen > /etc/uuid'";
      };
    };

    environment.systemPackages =
      (with pkgs; [
        alsa-utils
        i2c-tools
        sox
        pipewire
        wireplumber
        libgpiod
        cifs-utils
        util-linux
      ])
      ++ (with hb; [
        configurator
        hateeprom
        audiocontrol
        hifiberry-dsp
        dspprofiles
        pipewire-api
      ]);

    networking.hostName = lib.mkDefault "hifiberry";
    # HiFiBerryOS (Raspberry Pi OS) runs no firewall; AirPlay, Spotify Connect,
    # Roon and Sendspin negotiate ports dynamically.
    networking.firewall.enable = lib.mkDefault false;
    networking.networkmanager.enable = lib.mkDefault true;
    networking.wireless.enable = lib.mkForce false;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        userServices = true;
        workstation = true;
      };
      # avahi-services/hifiberry.service of hifiberry-configurator
      extraServiceFiles.hifiberry = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">HiFiBerry (%h)</name>
          <service>
            <type>_hifiberry._tcp</type>
            <port>80</port>
          </service>
        </service-group>
      '';
    };

    services.openssh = lib.mkIf cfg.openssh.enable {
      enable = true;
      settings.PasswordAuthentication = lib.mkDefault true;
    };

    security.sudo.enable = true;
    security.rtkit.enable = true;
    services.dbus.enable = true;

    # i2c-dev for sound card detection (config-server-i2c.conf in HiFiBerryOS)
    boot.kernelModules = [ "i2c-dev" ];

    hardware.enableRedistributableFirmware = true;
  };
}
