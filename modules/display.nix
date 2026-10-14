# nowplaying-sdl: the SDL2 now-playing display for a small attached screen
# (HiFiBerryOS' "Local display" feature).
{
  config,
  lib,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
in
{
  options.hifiberry.display.nowplaying.enable =
    lib.mkEnableOption "the SDL2 now-playing display (nowplaying-sdl)";

  config = lib.mkIf (cfg.enable && cfg.display.nowplaying.enable) {
    environment.systemPackages = [ hb.nowplaying-sdl ];
    hardware.graphics.enable = true;

    hifiberry.internal.defaultEnabledUserServices = [ "nowplaying-sdl" ];

    systemd.user.units."nowplaying-sdl.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry Now Playing Display";
      execStart = "${hb.nowplaying-sdl}/bin/nowplaying-sdl";
      after = [ "graphical.target" ];
      restart = "always";
      environment = [
        "SDL_VIDEODRIVER=kmsdrm"
        "XDG_RUNTIME_DIR=/run/user/${toString cfg.uid}"
      ];
    };
    environment.etc."nowplaying_sdl.conf".source =
      "${hb.nowplaying-sdl}/share/nowplaying-sdl/nowplaying_sdl.conf";
  };
}
