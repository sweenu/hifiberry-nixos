# What the web interface's first-run setup wizard asks, declared in the
# configuration instead (see the `hifiberry.setup` options).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
  setup = cfg.setup;
  auth = setup.webAuth;
  hb = cfg.packages;

  # hostconfig.sanitize_hostname: lowercase, spaces to hyphens, only
  # [a-z0-9-], no repeated or edge hyphens, "hifiberry" if nothing is left.
  toHostname =
    name:
    let
      kept = lib.filter (c: lib.elem c (lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz0123456789-")) (
        lib.stringToCharacters (lib.replaceStrings [ " " ] [ "-" ] (lib.toLower name))
      );
      joined = lib.concatStringsSep "-" (
        lib.filter (part: part != "") (lib.splitString "-" (lib.concatStrings kept))
      );
      hostname = lib.removeSuffix "-" (builtins.substring 0 63 joined);
    in
    if hostname == "" then "hifiberry" else hostname;

  hashFile =
    if auth.hashedPasswordFile != null then
      auth.hashedPasswordFile
    else if auth.hashedPassword != null then
      pkgs.writeText "hifiberry-web-password-hash" auth.hashedPassword
    else
      null;

  # hifiberry-auth keeps its state in a small SQLite key/value table
  # (hifiberry_auth/store.py); write the policy and the hash the way it does.
  applyAuth = pkgs.writers.writePython3 "hifiberry-auth-declare" { } ''
    import os
    import sqlite3
    import sys

    db, protection = sys.argv[1], sys.argv[2]
    hash_path = os.path.join(os.environ.get("CREDENTIALS_DIRECTORY", ""), "hash")

    c = sqlite3.connect(db)
    c.execute("CREATE TABLE IF NOT EXISTS auth_kv "
              "(key TEXT PRIMARY KEY, value TEXT)")
    c.execute("CREATE TABLE IF NOT EXISTS sessions (sid TEXT PRIMARY KEY, "
              "exp INTEGER NOT NULL, created INTEGER NOT NULL)")


    def get(key):
        row = c.execute("SELECT value FROM auth_kv WHERE key=?",
                        (key,)).fetchone()
        return row[0] if row else None


    def put(key, value):
        c.execute("INSERT INTO auth_kv (key, value) VALUES (?, ?) "
                  "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                  (key, value))


    changed = False
    if os.path.exists(hash_path):
        with open(hash_path) as f:
            password_hash = f.read().strip()
        if not password_hash.startswith("$argon2"):
            sys.exit("the web password hash is not an argon2 hash")
        if get("password_hash") != password_hash:
            put("password_hash", password_hash)
            changed = True
    if get("protection") != protection:
        put("protection", protection)
        changed = True
    if changed:
        # Sign everyone out: their sessions were granted under other settings.
        c.execute("DELETE FROM sessions")
    c.commit()
  '';
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (setup.systemName != null) {
        networking.hostName = toHostname setup.systemName;
        environment.etc."machine-info".text = ''
          PRETTY_HOSTNAME=${lib.escapeShellArg setup.systemName}
        '';
      })

      (lib.mkIf setup.skipWizard {
        systemd.services.hifiberry-setup-complete = {
          description = "Mark the first-run setup as done (declared in the configuration)";
          wantedBy = [ "multi-user.target" ];
          before = [ "config-server.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${hb.configurator}/bin/config-db --set system.setup_completed true";
          };
        };
      })

      (lib.mkIf (auth.protection != null) {
        assertions = [
          {
            assertion = auth.protection == "off" || hashFile != null;
            message = "hifiberry.setup.webAuth.protection = \"${auth.protection}\" needs hifiberry.setup.webAuth.hashedPassword or hashedPasswordFile.";
          }
        ];

        systemd.services.hifiberry-auth-declare = {
          description = "Apply the declared web interface password and protection";
          wantedBy = [ "multi-user.target" ];
          before = [ "hifiberry-auth.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "hifiberry-auth";
            Group = "hifiberry-auth";
            StateDirectory = "hifiberry-auth";
            StateDirectoryMode = "0750";
            ExecStart = "${applyAuth} /var/lib/hifiberry-auth/auth.db ${auth.protection}";
          }
          // lib.optionalAttrs (hashFile != null && auth.protection != "off") {
            LoadCredential = "hash:${hashFile}";
          };
        };
      })
    ]
  );
}
