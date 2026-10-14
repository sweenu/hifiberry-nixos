# Kiosk mode: cage (Wayland kiosk compositor) running cog (WPE WebKit) on tty1,
# showing the web interface on a locally attached screen (docs/kiosk-mode.md).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry.kiosk;
in
{
  options.hifiberry.kiosk = {
    enable = lib.mkEnableOption "kiosk mode: the web interface on the local display";
    url = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost/now-playing-minimal";
      description = "Page to display.";
    };
    scale = lib.mkOption {
      type = lib.types.str;
      default = "1.3";
      description = "Browser zoom factor; increase for large or distant screens.";
    };
    dark = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Append `?dark` so the now-playing view uses the dark theme.";
    };
  };

  config = lib.mkIf (config.hifiberry.enable && cfg.enable) {
    services.cage = {
      enable = true;
      user = config.hifiberry.user;
      program = "${pkgs.cog}/bin/cog --platform=wl --scale=${cfg.scale} ${
        lib.escapeShellArg (cfg.url + lib.optionalString cfg.dark "?dark")
      }";
      environment.COG_PLATFORM_DRM_CURSOR = "0";
    };
    hardware.graphics.enable = true;
  };
}
