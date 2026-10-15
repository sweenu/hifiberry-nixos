# Kiosk mode: a full-screen browser on the HDMI output showing the web
# interface's now-playing page, as HiFiBerryOS' kiosk-mode.sh sets up.
# HiFiBerryOS runs cog (WPE WebKit) in cage; nixpkgs has no WPE WebKit, so this
# runs Chromium in cage (NixOS' services.cage), which is cached for aarch64.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  k = cfg.kiosk;

  # Runs inside cage, which sets WAYLAND_DISPLAY. The zoom is the outputs'
  # scale: Chromium's --force-device-scale-factor is rounded up to a whole
  # buffer scale on Wayland and leaves the page in a corner of the screen.
  browser = pkgs.writeShellScript "hifiberry-kiosk-browser" ''
    for output in $(${lib.getExe pkgs.wlr-randr} | ${lib.getExe pkgs.gawk} '/^[^ ]/ { print $1 }'); do
      ${lib.getExe pkgs.wlr-randr} --output "$output" --scale ${builtins.toJSON k.scale} || true
    done
    # Give the web interface up to a minute to answer before showing it.
    for _ in $(seq 30); do
      ${lib.getExe pkgs.curl} -sf -o /dev/null ${lib.escapeShellArg k.url} && break
      sleep 2
    done
    # --app drops the tab strip and address bar, which --kiosk alone keeps
    # under cage. A network service that crashes while the page loads leaves
    # a blank window behind; in the browser process, its crash ends the browser
    # and the service starts it again. --enable-auto-reload retries error
    # pages.
    exec ${lib.getExe k.package} \
      --kiosk \
      --app=${lib.escapeShellArg k.url} \
      --incognito \
      --ozone-platform=wayland \
      --noerrdialogs \
      --no-first-run \
      --disable-infobars \
      --disable-features=Translate \
      --enable-features=NetworkServiceInProcess2 \
      --enable-auto-reload \
      --disable-background-networking \
      --disable-component-update \
      --password-store=basic \
      ${lib.escapeShellArgs k.extraArguments}
  '';
in
{
  options.hifiberry.kiosk = {
    enable = lib.mkEnableOption ''
      kiosk mode: a full-screen browser on the HDMI output, started at boot,
      showing the web interface's now-playing page. SSH and the web interface
      are unaffected. The browser runs as `hifiberry.user` in cage on tty1
      (`services.cage`); set `services.cage.program` to run something else
    '';

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost/now-playing-minimal?dark";
      example = "http://localhost/now-playing";
      description = ''
        Page to display. `?dark` forces the dark theme of the now-playing
        pages; leave it out to follow the web interface's theme.
      '';
    };

    scale = lib.mkOption {
      type = lib.types.numbers.positive;
      default = 1.3;
      example = 1.5;
      description = ''
        Zoom factor, applied as the scale of the screen. A TV often reports a
        wrong physical size, so raise it for large or distant screens: about
        1.0 for a 24" monitor, 1.2-1.3 for a 40-50" TV, 1.4-1.5 for a 55-70"
        TV.
      '';
    };

    package = lib.mkPackageOption pkgs "chromium" { };

    extraArguments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--enable-features=NetworkServiceInProcess2,OverlayScrollbar" ];
      description = ''
        Additional command line arguments for Chromium. Chromium reads only
        the last `--enable-features`, so repeat `NetworkServiceInProcess2` in
        one you add.
      '';
    };

    ignoreHdmiInput = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Tell libinput to ignore the HDMI (CEC) input device. The Raspberry Pi
        reports it as an input device, which otherwise leaves a mouse cursor
        stuck in the middle of the screen when no mouse is plugged in.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && k.enable) {
    services.cage = {
      enable = true;
      user = lib.mkDefault cfg.user;
      program = lib.mkDefault browser;
      # A display with nothing plugged in but the screen is the normal case;
      # without this cage refuses to start when it finds no input device.
      environment.WLR_LIBINPUT_NO_DEVICES = lib.mkDefault "1";
    };

    systemd.services.cage-tty1 = {
      # Open the page once the web interface is being served.
      wants = [ "nginx.service" ];
      after = [ "nginx.service" ];
      # The browser exiting ends cage; bring the screen back. cage also exits
      # when the display driver is not up yet, so keep trying.
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Restart = "always";
        RestartSec = 2;
      };
    };

    services.udev.extraRules = lib.mkIf k.ignoreHdmiInput ''
      SUBSYSTEM=="input", ATTRS{name}=="vc4-hdmi*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };
}
