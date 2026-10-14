# AudioControl: the player daemon (port 1080) and the metadata daemon (1084).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
  acr =
    if cfg.audiocontrol.secretsFile != null then
      hb.audiocontrol.override { secretsFile = cfg.audiocontrol.secretsFile; }
    else
      hb.audiocontrol;
in
{
  config = lib.mkIf cfg.enable {
    warnings = lib.optional (cfg.audiocontrol.secretsFile == null) ''
      hifiberry.audiocontrol.secretsFile is not set: AudioControl is built without
      HiFiBerry's API credentials, so Last.fm scrobbling, TheAudioDB lookups and the
      Spotify account link will not work. Everything else does.
    '';

    users.users.audiocontrol = {
      isSystemUser = true;
      group = "audiocontrol";
      home = "/etc/audiocontrol";
      extraGroups = [
        "audio"
        "input"
      ];
    };
    users.groups.audiocontrol = { };

    hifiberry.internal = {
      nginxSnippets = [ "${acr}/share/hifiberry-audiocontrol/nginx/hifiberry-audiocontrol.nginx" ];
      authManifests = {
        "audiocontrol-auth.json" = "${acr}/share/hifiberry/auth.d/audiocontrol-auth.json";
        "audiocontrol-metadata-auth.json" = "${acr}/share/hifiberry/auth.d/audiocontrol-metadata-auth.json";
      };
      acrPlayers."mpris.json" = "${acr}/etc/audiocontrol/players.d/mpris.json";
    };

    environment.etc = {
      "audiocontrol/audiocontrol.json".source = "${acr}/etc/audiocontrol/audiocontrol.json";
      "audiocontrol/metadata.json".source = "${acr}/etc/audiocontrol/metadata.json";
      "audiocontrol/logging.json".source = "${acr}/etc/audiocontrol/logging.json";
      "audiocontrol/genres.json".source = "${acr}/etc/audiocontrol/genres.json";
    }
    // lib.mapAttrs' (
      name: path: lib.nameValuePair "audiocontrol/players.d/${name}" { source = path; }
    ) cfg.internal.acrPlayers;

    systemd.tmpfiles.rules = [
      "d /var/lib/audiocontrol 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/cache 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/cache/attributes 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/cache/images 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/cache/artists 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/user 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/user/images 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/db 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/metadata 0755 audiocontrol audiocontrol -"
      "d /var/lib/audiocontrol/metadata/images 0755 audiocontrol audiocontrol -"
    ];

    systemd.services.audiocontrol = {
      description = "HiFiBerry AudioControl - Audio Player Management Service";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "sound.target"
        "config-server.service"
        "systemd-udev-settle.service"
      ];
      wants = [ "sound.target" ];
      unitConfig.ConditionPathExists = "/proc/asound/cards";
      path = [
        hb.configurator
        pkgs.alsa-utils
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${acr}/bin/audiocontrol -c /etc/audiocontrol/audiocontrol.json --log-config /etc/audiocontrol/logging.json";
        Restart = "on-failure";
        RestartSec = 5;
        User = "audiocontrol";
        Group = "audiocontrol";
        SupplementaryGroups = [
          "audio"
          "input"
        ];
        WorkingDirectory = "/etc/audiocontrol";
        RuntimeDirectory = "audiocontrol";
        RuntimeDirectoryMode = "0755";
        Environment = [
          "PULSE_RUNTIME_PATH=/run/pulse"
          "XDG_RUNTIME_DIR=/run/audiocontrol"
        ];
        TimeoutStopSec = 10;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        FinalKillSignal = "SIGKILL";
      };
    };

    systemd.services.audiocontrol-metadata = {
      description = "HiFiBerry AudioControl metadata service";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "audiocontrol.service"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${acr}/bin/audiocontrol-metadata -c /etc/audiocontrol/metadata.json";
        Restart = "on-failure";
        RestartSec = 5;
        User = "audiocontrol";
        Group = "audiocontrol";
        TimeoutStopSec = 10;
      };
    };
  };
}
