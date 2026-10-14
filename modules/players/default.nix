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
    sendspin = playerOpts {
      name = "sendspin";
      description = "Music Assistant (Sendspin)";
      default = true;
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
