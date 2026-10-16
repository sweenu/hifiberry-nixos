# Players. Each is a systemd *user* service of the player user, as in
# HiFiBerryOS, registered with AudioControl (players.d), the web interface's
# player registry (share/hifiberry/players.d) and the configurator (conf.d).
{
  config,
  lib,
  ...
}:
let
  cfg = config.hifiberry;

  playerOpts =
    {
      name,
      description,
      default ? false,
    }:
    {
      enable = lib.mkEnableOption description // {
        inherit default;
      };
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = cfg.players.${name}.enable;
        defaultText = lib.literalExpression "config.hifiberry.players.${name}.enable";
        description = ''
          Enable the ${description} service in the player user's session on
          the first boot (what installing the package does on HiFiBerryOS).
          The web interface can switch it on and off afterwards.
        '';
      };
    };
in
{
  imports = [
    ./mpd.nix
    ./librespot.nix
    ./shairport.nix
    ./squeezelite.nix
    ./sendspin.nix
    ./raat.nix
    ./analog-recognition.nix
    ./aes67.nix
    ./usbaudio.nix
    ./analoginput.nix
  ];

  options.hifiberry.players = {
    mpd = playerOpts {
      name = "mpd";
      description = "Music Player Daemon (local and network music files)";
    };
    librespot = playerOpts {
      name = "librespot";
      description = "Spotify Connect (librespot)";
    };
    shairport = playerOpts {
      name = "shairport";
      description = "AirPlay (shairport-sync)";
    };
    squeezelite = playerOpts {
      name = "squeezelite";
      description = "Squeezebox/Lyrion Music Server client (squeezelite)";
    };
    sendspin =
      playerOpts {
        name = "sendspin";
        description = "Music Assistant (Sendspin)";
        default = true;
      }
      // {
        protocol = lib.mkOption {
          type = lib.types.enum [
            "legacy"
            "v1"
          ];
          default = "legacy";
          description = ''
            Which Sendspin protocol the player speaks.

            `legacy` is the pre-1.0 sendspin-cpp that HiFiBerry's own
            hifiberry-sendspin pins, and is what every released Music Assistant
            talks to. Those servers treat it as a legacy client: playback works,
            but the stream is torn down on pause and can collapse shortly after
            resuming, and volume changes may not reach the speaker.

            `v1` builds sendspin-cpp 0.9, which speaks Sendspin 1.0: encrypted
            connections, a persistent client identity and pairing, and the timing
            fields that fix the behaviour above. It needs a server on
            aiosendspin 10 or newer — Music Assistant 2.11 or later. Against an
            older server the Noise handshake fails and the player never connects,
            so this stays off until your server is new enough.
          '';
        };
      };
    raat = playerOpts {
      name = "raat";
      description = "Roon Ready (RAAT)";
    };
    analogRecognition = playerOpts {
      name = "analogRecognition";
      description = "analog input with track recognition (songrec)";
    };
    aes67 = playerOpts {
      name = "aes67";
      description = "AES67 receiver";
    };
    usbaudio = playerOpts {
      name = "usbaudio";
      description = "USB audio gadget input";
    };
    analoginput = playerOpts {
      name = "analoginput";
      description = "analog input pass-through";
    };
  };
}
