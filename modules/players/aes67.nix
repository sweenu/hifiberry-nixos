{
  config,
  lib,
  hifiberryLib,
  ...
}:
let
  cfg = config.hifiberry;
  p = cfg.players.aes67;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && p.enable) {
    hifiberry.internal = {
      acrPlayers."aes67.json" = "${hb.aes67}/etc/audiocontrol/players.d/aes67.json";
      configserverConfD."aes67.json" = "${hb.aes67}/etc/configserver/conf.d/aes67.json";
      authManifests."aes67.json" = "${hb.aes67}/share/hifiberry/auth.d/aes67.json";
      nginxSnippets = [ "${hb.aes67}/share/hifiberry-aes67/nginx/hifiberry-aes67.nginx" ];
      sharePackages = [ hb.aes67 ];
      defaultEnabledUserServices = lib.optionals p.autoStart [
        "aes67-agent"
        "aes67"
      ];
      extensions = [
        (hifiberryLib.mkExtensionRecord {
          package = "hifiberry-aes67";
          name = "AES67";
          icon = "/images/svg/network.svg";
          description = "AES67 receiver for HiFiBerryOS";
          version = hb.aes67.version;
        })
      ];
    };

    environment.systemPackages = [ hb.aes67 ];

    systemd.user.units."aes67-agent.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry AES67 Agent (discovery API and player state)";
      execStart = "${hb.aes67}/bin/hifiberry-aes67 serve";
      wants = [ "pipewire.service" ];
    };
    systemd.user.units."aes67.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry AES67 Receiver";
      execStart = "${hb.aes67}/bin/hifiberry-aes67 connect --watch";
      execStop = "${hb.aes67}/bin/hifiberry-aes67 disconnect";
      after = [ "aes67-agent.service" ];
      wants = [ "pipewire.service" ];
    };
  };
}
