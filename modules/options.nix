{
  lib,
  pkgs,
  ...
}:
{
  options.hifiberry = {
    enable = lib.mkEnableOption "HiFiBerryOS (PipeWire, AudioControl, configurator, web interface, players)";

    packages = lib.mkOption {
      type = lib.types.attrs;
      default = import ../pkgs { inherit pkgs; };
      defaultText = lib.literalExpression "import ../pkgs { inherit pkgs; }";
      description = "The HiFiBerryOS package set to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "hifiberry";
      description = ''
        The user whose systemd user session runs PipeWire and the players, as
        HiFiBerryOS does (written to /etc/hifiberry.user). Lingering is enabled
        for this user so its services start at boot without a login.
      '';
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID of the player user.";
    };

    initialPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "hifiberry";
      description = ''
        Initial password of the player user, for SSH and console access on the
        first boot. Set to null when you configure `users.users.<user>` yourself.
      '';
    };

    soundcard = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "hifiberry-dacplus";
      description = ''
        Device tree overlay of the HiFiBerry sound card, as it would appear
        after `dtoverlay=` in config.txt (for example `hifiberry-dacplus`,
        `hifiberry-dacplusadcpro`, `hifiberry-digi-pro`, `hifiberry-amp100,automute`).

        `null` keeps HiFiBerryOS' behaviour: the card is detected on boot
        (HAT EEPROM, I2C), the overlay is written to /boot/firmware/hifiberry.txt,
        which config.txt includes, and the device reboots once. Setting the
        overlay here puts it in config.txt itself, so no detection reboot is
        needed and the setting survives `nixos-rebuild`.
      '';
    };

    setup = {
      skipWizard = lib.mkEnableOption ''
        skipping the web interface's first-run setup wizard. Declare what it
        would ask here instead: `hifiberry.setup.systemName`,
        `hifiberry.setup.webAuth`, `hifiberry.soundcard` and
        `hifiberry.players.*.enable`. Anything left undeclared keeps its
        default and can still be changed from the web interface's settings
      '';

      systemName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Bedroom speakers";
        description = ''
          The device name shown in Music Assistant and the web interface. The
          hostname (and so the `.local` mDNS name) is derived from it as the
          configurator does: "Bedroom speakers" becomes `bedroom-speakers`.
          When set, the name is fixed by the configuration and can no longer be
          changed from the web interface. `null` leaves it to the setup wizard
          and the system settings (default `hifiberry`).
        '';
      };

      webAuth = {
        protection = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "off"
              "risky"
              "all"
            ]
          );
          default = null;
          description = ''
            Which web interface actions need the device password
            (hifiberry-auth's protection policy): `off` (none), `risky`
            (system changes: network, name, installs, resets) or `all` (the
            whole interface). Applied at every boot, together with the
            password, replacing what was set from the web interface. `null`
            leaves both to the setup wizard and the web interface.
          '';
        };

        hashedPassword = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            argon2id hash of the device password, required for the `risky` and
            `all` policies. Create one with
            `nix run github:sweenu/hifiberry-nixos#hash-password`. The hash
            ends up in the Nix store; use `hashedPasswordFile` to keep it out.
          '';
        };

        hashedPasswordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "/run/secrets/hifiberry-web-password-hash";
          description = ''
            Path, read at boot, to a file holding the argon2id hash (for
            example from sops-nix or agenix). Takes precedence over
            `hashedPassword`.
          '';
        };
      };
    };

    audiocontrol.secretsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        A `secrets.txt` (see secrets.txt.sample in hifiberry/acr) with the API
        credentials AudioControl bakes into its binary: Last.fm, TheAudioDB and
        HiFiBerry's Spotify OAuth proxy. Without it everything works except
        scrobbling, TheAudioDB lookups and linking a Spotify account. The file
        is copied into the Nix store.
      '';
    };

    bluetooth.enable = lib.mkEnableOption "Bluetooth audio (hifiberry-bluetooth)" // {
      default = true;
    };
    dsp.enable = lib.mkEnableOption "the DSP toolkit (sigmatcpserver) and DSP profiles" // {
      default = true;
    };
    roomeq.enable = lib.mkEnableOption "the RoomEQ room correction service" // {
      default = true;
    };
    vuMeter.enable = lib.mkEnableOption "the VU meter service" // {
      default = true;
    };
    bleProvisioning.enable = lib.mkEnableOption "Wi-Fi provisioning over Bluetooth LE" // {
      default = true;
    };
    webmcp.enable = lib.mkEnableOption "the AudioControl MCP server (acr-webmcp)";
    openssh.enable = lib.mkEnableOption "SSH access with password authentication" // {
      default = true;
    };

    # Aggregated by the component modules.
    internal = {
      nginxSnippets = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        internal = true;
        description = "nginx location snippets (/etc/nginx/hifiberry-api.d in HiFiBerryOS).";
      };
      authManifests = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        internal = true;
        description = "hifiberry-auth classification manifests (/etc/hifiberry/auth.d).";
      };
      acrPlayers = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        internal = true;
        description = "AudioControl player definitions (/etc/audiocontrol/players.d).";
      };
      configserverConfD = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        internal = true;
        description = "configurator drop-ins (/etc/configserver/conf.d).";
      };
      extensions = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        internal = true;
        description = "Extension records shown by the web interface.";
      };
      defaultEnabledUserServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        internal = true;
        description = "User services enabled in the player user's manager on first boot.";
      };
      sharePackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        internal = true;
        description = "Packages whose share/hifiberry is exposed as /usr/share/hifiberry.";
      };
    };
  };
}
