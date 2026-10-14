# RoomEQ: room correction measurements and optimizer (REST API on 10315).
{
  config,
  lib,
  ...
}:
let
  cfg = config.hifiberry;
  hb = cfg.packages;
in
{
  config = lib.mkIf (cfg.enable && cfg.roomeq.enable) {
    hifiberry.internal = {
      nginxSnippets = [ "${hb.roomeq}/share/roomeq/nginx/hifiberry-roomeq.nginx" ];
      authManifests."roomeq.json" = "${hb.roomeq}/share/hifiberry/auth.d/roomeq.json";
      sharePackages = [ hb.roomeq ];
    };

    users.users.roomeq = {
      isSystemUser = true;
      group = "roomeq";
      home = "/var/lib/roomeq";
      extraGroups = [ "audio" ];
    };
    users.groups.roomeq = { };

    systemd.services.roomeq-server = {
      description = "RoomEQ REST API";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${hb.roomeq}/bin/roomeq-server";
        Restart = "always";
        User = "roomeq";
        Group = "roomeq";
        StateDirectory = "roomeq";
        WorkingDirectory = "/var/lib/roomeq";
        Environment = [ "HOME=/var/lib/roomeq" ];
      };
    };
  };
}
