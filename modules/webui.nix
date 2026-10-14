# nginx on port 80 as the single front door: the web interface, the API
# reverse proxies of every service, and the hifiberry-auth gateway.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;

  # HiFiBerry's snippet, pointed at the store path. Its security headers sit at
  # server level, but a nested `add_header` (Cache-Control in each location)
  # drops every inherited one, so they are repeated in each location. NixOS
  # rejects the unmodified snippet for that (gixy, add_header_redefinition).
  webuiNginx = pkgs.runCommand "hifiberry-webui.nginx" { } ''
    sed -e 's|/usr/share/hifiberry/webui|${hb.webui}/share/hifiberry/webui|' \
        -e '/^ \{4\}add_header Cache-Control/a\
        add_header X-Frame-Options "SAMEORIGIN" always;\
        add_header X-Content-Type-Options "nosniff" always;\
        add_header X-XSS-Protection "1; mode=block" always;' \
      ${hb.webui}/share/hifiberry-webui/nginx/hifiberry-webui.nginx > $out
  '';
  apiSnippets = pkgs.concatText "hifiberry-api.nginx" cfg.internal.nginxSnippets;
in
{
  config = lib.mkIf cfg.enable {
    hifiberry.internal.nginxSnippets = [
      "${hb.hifiberry-auth}/share/hifiberry-auth/nginx/hifiberry-auth.nginx"
    ];

    services.nginx = {
      enable = true;
      recommendedGzipSettings = false;
      virtualHosts.hifiberry = {
        default = true;
        serverName = "_";
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
          {
            addr = "[::]";
            port = 80;
          }
        ];
        extraConfig = ''
          include ${hb.hifiberry-auth}/share/hifiberry-auth/nginx/00-verify.conf;
          include ${apiSnippets};
          include ${webuiNginx};
        '';
      };
    };

    users.users.hifiberry-auth = {
      isSystemUser = true;
      group = "hifiberry-auth";
      home = "/var/lib/hifiberry-auth";
    };
    users.groups.hifiberry-auth = { };

    systemd.tmpfiles.rules = [ "d /etc/hifiberry/auth.d 0755 root root -" ];

    systemd.services.hifiberry-auth = {
      description = "HiFiBerry authentication/authorization gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      before = [ "nginx.service" ];
      # Manifests are read at startup only.
      restartTriggers = lib.attrValues cfg.internal.authManifests;
      serviceConfig = {
        Type = "simple";
        User = "hifiberry-auth";
        Group = "hifiberry-auth";
        ExecStart = "${hb.hifiberry-auth}/bin/hifiberry-auth --host 127.0.0.1 --port 1089";
        Restart = "always";
        RestartSec = 3;
        StateDirectory = "hifiberry-auth";
        StateDirectoryMode = "0750";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ "/var/lib/hifiberry-auth" ];
        CapabilityBoundingSet = "";
      };
    };
  };
}
