# acr-webmcp: MCP server exposing AudioControl to AI assistants.
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
in
{
  config = lib.mkIf (cfg.enable && cfg.webmcp.enable) {
    hifiberry.internal = {
      nginxSnippets = [ "${hb.acr-webmcp}/share/hifiberry-acr-webmcp/nginx/hifiberry-acr-webmcp.nginx" ];
      defaultEnabledUserServices = [ "acr-webmcp" ];
    };
    environment.systemPackages = [ hb.acr-webmcp ];

    systemd.user.units."acr-webmcp.service".text = hifiberryLib.mkPlayerUnit {
      description = "HiFiBerry ACR Web MCP Service";
      execStart = "${hb.acr-webmcp}/bin/acr-webmcp --transport http --host 127.0.0.1 --port 13180";
      execStartPre = [ "${pkgs.coreutils}/bin/sleep 2" ];
    };
  };
}
