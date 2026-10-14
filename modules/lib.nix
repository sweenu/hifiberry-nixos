{ lib }:
rec {
  # Render a systemd unit file from an attribute set of sections, keeping the
  # [Install] section so that `systemctl --user enable/disable` works from the
  # web interface (NixOS does not emit [Install] sections for units it manages).
  renderUnit =
    sections:
    let
      order = [
        "Unit"
        "Service"
        "Install"
      ];
      names = order ++ lib.subtractLists order (lib.attrNames sections);
    in
    lib.concatStringsSep "\n" (
      map (
        section:
        let
          entries = sections.${section};
        in
        "[${section}]\n"
        + lib.concatStringsSep "\n" (
          lib.flatten (
            lib.mapAttrsToList (k: v: map (x: "${k}=${toString x}") (if lib.isList v then v else [ v ])) entries
          )
        )
        + "\n"
      ) (lib.filter (n: sections ? ${n}) names)
    );

  # A player user unit as HiFiBerryOS ships them: Type=simple, restarts on
  # failure, installed into default.target of the player user's manager.
  mkPlayerUnit =
    {
      description,
      execStart,
      after ? [ ],
      wants ? [ ],
      before ? [ ],
      partOf ? [ ],
      conditionPathExists ? null,
      execCondition ? null,
      execStartPre ? [ ],
      execStartPost ? [ ],
      execStop ? null,
      restartSec ? 5,
      restart ? "on-failure",
      environment ? [ ],
      type ? "simple",
      remainAfterExit ? false,
      extraService ? { },
      extraUnit ? { },
    }:
    renderUnit {
      Unit = {
        Description = description;
        After = [
          "sound.target"
          "network.target"
          "pipewire.service"
        ]
        ++ after;
      }
      // lib.optionalAttrs (wants != [ ]) { Wants = wants; }
      // lib.optionalAttrs (before != [ ]) { Before = before; }
      // lib.optionalAttrs (partOf != [ ]) { PartOf = partOf; }
      // lib.optionalAttrs (conditionPathExists != null) { ConditionPathExists = conditionPathExists; }
      // extraUnit;
      Service = {
        Type = type;
        ExecStart = execStart;
        Restart = restart;
        RestartSec = restartSec;
      }
      // lib.optionalAttrs (execCondition != null) { ExecCondition = execCondition; }
      // lib.optionalAttrs (execStartPre != [ ]) { ExecStartPre = execStartPre; }
      // lib.optionalAttrs (execStartPost != [ ]) { ExecStartPost = execStartPost; }
      // lib.optionalAttrs (execStop != null) { ExecStop = execStop; }
      // lib.optionalAttrs (environment != [ ]) { Environment = environment; }
      // lib.optionalAttrs remainAfterExit { RemainAfterExit = "yes"; }
      // extraService;
      Install = {
        WantedBy = "default.target";
      };
    };

  # The "Hifiberry-Extension" apt record the web interface's extension catalog
  # shows for a player, as written by the NixOS module to
  # /etc/hifiberry/nixos-extensions.json.
  mkExtensionRecord =
    {
      package,
      name,
      category ? "player",
      icon,
      description,
      version,
      installed ? true,
    }:
    {
      inherit name version installed;
      record = {
        "Package" = package;
        "Version" = version;
        "Hifiberry-Extension" = "yes";
        "Extension-Name" = name;
        "Extension-Category" = category;
        "Extension-Needs-Reboot" = "no";
        "Extension-Icon-Url" = icon;
        "Description" = description;
      };
    }
    // {
      name = package;
    };
}
