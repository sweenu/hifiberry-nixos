# PipeWire as HiFiBerryOS runs it: in the player user's session, with the
# HiFiBerry rate policy, headless overrides, the WirePlumber rules, the speaker
# EQ and analog input processor filter chains, and the pipewire-api service.
{
  config,
  lib,
  pkgs,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
  pwSrc = "${hb.sources.hifiberry-os}/packages/pipewire-configs/src/etc";

  # The filter chain configs name the plugins by their Debian path.
  inputProcessorConf = pkgs.runCommand "90-input-processor.conf" { } ''
    sed 's|/usr/lib/ladspa/riaa.so|${hb.input-processor}/lib/ladspa/riaa.so|' \
      ${hb.input-processor}/share/hifiberry-input-processor/pipewire/90-input-processor.conf > $out
  '';
  speakereqConf = pkgs.runCommand "90-speakereq.conf" { } ''
    sed 's|/usr/lib/ladspa/speakereq2x2.so|${hb.speakereq}/lib/ladspa/speakereq2x2.so|' \
      ${hb.speakereq}/share/ladspa-speakereq/pipewire/90-speakereq.conf > $out
  '';

  pipewireConfPkg = pkgs.runCommand "hifiberry-pipewire-conf" { } ''
    d=$out/share/pipewire/pipewire.conf.d
    mkdir -p $d
    cp ${pwSrc}/pipewire/pipewire.conf.d/10-hifiberry-rates.conf $d/
    cp ${pwSrc}/pipewire/pipewire.conf.d/99-hifiberry-headless.conf $d/
    cp ${inputProcessorConf} $d/90-input-processor.conf
    cp ${speakereqConf} $d/90-speakereq.conf
  '';
  wireplumberConfPkg = pkgs.runCommand "hifiberry-wireplumber-conf" { } ''
    d=$out/share/wireplumber/wireplumber.conf.d
    mkdir -p $d
    cp ${pwSrc}/xdg/wireplumber/wireplumber.conf.d/90-default-volume.conf $d/
    cp ${pwSrc}/xdg/wireplumber/wireplumber.conf.d/91-hide-midi-ui.conf $d/
    cp ${pwSrc}/xdg/wireplumber/wireplumber.conf.d/98-hifiberry-digi-no-capture.conf $d/
    ${lib.optionalString cfg.bluetooth.enable "cp ${pwSrc}/xdg/wireplumber/wireplumber.conf.d/99-hifiberry-bluetooth.conf $d/"}
    cp ${hb.input-processor}/share/hifiberry-input-processor/wireplumber/99-input-processor-autoconnect.conf $d/
    cp ${hb.speakereq}/share/ladspa-speakereq/wireplumber/99-force-effect-filter.conf $d/
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      systemWide = false;
      audio.enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = false;
      wireplumber.enable = true;
      configPackages = [ pipewireConfPkg ];
      wireplumber.configPackages = [ wireplumberConfPkg ];
      extraLadspaPackages = [
        hb.input-processor
        hb.speakereq
      ];
    };

    hifiberry.internal = {
      nginxSnippets = [ "${hb.pipewire-api}/share/pipewire-api/nginx/hifiberry-pipewire.nginx" ];
      authManifests."pipewire.json" = "${hb.pipewire-api}/share/hifiberry/auth.d/pipewire.json";
      defaultEnabledUserServices = [ "pipewire-api" ];
    };

    environment.etc = {
      "pipewire-api/link-rules.conf".source = "${hb.pipewire-api}/etc/pipewire-api/link-rules.conf";
      "pipewire-api/volume.conf".source = "${hb.pipewire-api}/etc/pipewire-api/volume.conf";
      "pipewire-api/param-rules.conf".source = "${hb.pipewire-api}/etc/pipewire-api/param-rules.conf";
    };

    systemd.user.units."pipewire-api.service".text = hifiberryLib.renderUnit {
      Unit = {
        Description = "PipeWire REST API Server";
        After = "pipewire.service";
        Requires = "pipewire.service";
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${hb.pipewire-api}/bin/pipewire-api --log-level info";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = "default.target";
    };
  };
}
