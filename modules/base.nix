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
  noSshKey =
    config.users.users.${cfg.user}.openssh.authorizedKeys.keys == [ ]
    && config.users.users.${cfg.user}.openssh.authorizedKeys.keyFiles == [ ];

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
      # A primary group with the same number as the user, as on Raspberry Pi
      # OS: the configurator runs `systemd-run --uid N --gid N` to manage the
      # player's services and fails if group N does not exist.
      group = cfg.user;
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
      ${cfg.user}.gid = cfg.uid;
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
          install -d -o ${cfg.user} -g ${cfg.user} "$home/.config" "$home/.config/systemd" "$home/.config/systemd/user" "$wants"
          ln -sfn "/etc/systemd/user/$svc.service" "$wants/$svc.service"
          chown -h ${cfg.user}:${cfg.user} "$wants/$svc.service"
          touch "$marker"
        done
      '';
    };

    # `systemctl --user enable` with an absolute path (what the web interface
    # does when it toggles a player) links the unit by its store path into
    # ~/.config/systemd/user, which the user manager searches before
    # /etc/systemd/user. The player then stays on the generation it was enabled
    # from and no later update reaches it. Re-point those links on every
    # activation, leaving the enabled/disabled state alone.
    system.activationScripts.hifiberry-unpin-user-units = {
      deps = [ "users" ];
      text = ''
        (
          home=$(${pkgs.getent}/bin/getent passwd ${cfg.user} | cut -d: -f6)
          userdir="$home/.config/systemd/user"
          [ -d "$userdir" ] || exit 0
          for link in "$userdir"/*.service "$userdir"/default.target.wants/*.service; do
            [ -L "$link" ] || continue
            case "$(readlink "$link")" in
              /nix/store/*) ;;
              *) continue ;;
            esac
            svc=$(basename "$link")
            [ -e "/etc/systemd/user/$svc" ] || continue
            case "$link" in
              */default.target.wants/*)
                ln -sfn "/etc/systemd/user/$svc" "$link"
                chown -h ${cfg.user}:${cfg.user} "$link"
                ;;
              # A top-level link only shadows /etc; the wants link above is
              # what keeps the service enabled, so dropping it is safe.
              *) rm -f "$link" ;;
            esac
          done
        ) || true
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

    # The name is the user's to change (setup wizard, system settings), so it is
    # not set here: /etc/hostname stays writable for hostnamectl, and
    # DEFAULT_HOSTNAME makes it "hifiberry" until it is changed.
    networking.hostName = lib.mkDefault "";
    system.nixos.extraOSReleaseArgs.DEFAULT_HOSTNAME = lib.mkDefault "hifiberry";
    # The system's name (store paths, the VM script and its disk) follows the
    # hostname when the configuration sets one, and is "hifiberry" otherwise.
    system.name = lib.mkDefault (
      if config.networking.hostName != "" then config.networking.hostName else "hifiberry"
    );
    # NixOS points hostnamed at the read-only /etc/static copies; with the name
    # unmanaged, let it write the real files.
    systemd.services.systemd-hostnamed.environment = {
      SYSTEMD_ETC_HOSTNAME = lib.mkForce "/etc/hostname";
      SYSTEMD_ETC_MACHINE_INFO = lib.mkForce "/etc/machine-info";
    };
    # Keep the name the user chose rather than one from DHCP or reverse DNS.
    networking.networkmanager.settings.main.hostname-mode = lib.mkDefault "none";

    # Avahi and Sendspin read the name when they start; announce a new one.
    systemd.paths.hifiberry-hostname = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = [
        "/etc/hostname"
        "/etc/machine-info"
      ];
    };
    systemd.services.hifiberry-hostname = {
      description = "Announce the new system name";
      serviceConfig.Type = "oneshot";
      script = ''
        systemctl try-restart avahi-daemon.service
        systemctl --user -M ${cfg.user}@ try-restart sendspin.service || true
      '';
    };
    # NetworkManager: the configurator's network settings, wifi.txt and Wi-Fi
    # setup over Bluetooth LE all go through it.
    networking.networkmanager.enable = lib.mkDefault true;
    # NetworkManager runs wpa_supplicant through networking.wireless (in its
    # D-Bus controlled mode); turning that option off leaves Wi-Fi unable to connect.

    services.avahi = {
      enable = true;
      nssmdns4 = lib.mkDefault true;
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
      # The initial password is public: only accept passwords (directly or
      # through keyboard-interactive PAM) until a key is set up.
      settings = {
        PasswordAuthentication = lib.mkDefault noSshKey;
        KbdInteractiveAuthentication = lib.mkDefault noSshKey;
      };
    };

    security.sudo.enable = lib.mkDefault true;
    security.rtkit.enable = true;
    services.dbus.enable = true;

    # i2c-dev for sound card detection (config-server-i2c.conf in HiFiBerryOS)
    boot.kernelModules = [ "i2c-dev" ];
    # /dev/i2c-* for the i2c group, so the player user's card detection can probe
    hardware.i2c.enable = true;

    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # A headless appliance on an SD card: a small closure, and a store that
    # does not fill the card.
    documentation.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    # An SD card wears out by being written to, and a player logs steadily for
    # years. Keep the journal in RAM, capped so it cannot crowd out a 512 MB
    # Pi: `journalctl` still works, it just starts empty after a reboot. Set
    # services.journald.storage = "persistent" to keep logs across reboots,
    # which is worth doing while chasing a boot-time problem.
    services.journald.storage = lib.mkDefault "volatile";
    services.journald.extraConfig = lib.mkDefault ''
      RuntimeMaxUse=32M
      RuntimeMaxFileSize=8M
    '';
    nix.gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 14d";
    };

    nix.settings = lib.mkMerge [
      { auto-optimise-store = lib.mkDefault true; }
      (lib.mkIf cfg.binaryCache.enable {
        substituters = [ "https://sweenu.cachix.org" ];
        trusted-public-keys = [ "sweenu.cachix.org-1:DvQl16NWBp41k5IlxTODTOrIThyGRj8/ekrXxEheBQ0=" ];
      })
    ];
  };
}
