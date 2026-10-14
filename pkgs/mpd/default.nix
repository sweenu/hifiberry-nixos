# hifiberry-mpd: MPD 0.24.13 with HiFiBerry's ALSA/PipeWire deadlock patch, plus
# the wrapper scripts (start-mpd, configure-mpd, mpd-reconcile,
# mpd-set-permissions) and the default configuration HiFiBerryOS ships.
{
  lib,
  stdenvNoCC,
  mpd,
  mpc,
  python3,
  configurator,
  acl,
  util-linux,
  makeWrapper,
  sources,
}:

let
  mpdSrc = "${sources.hifiberry-os}/packages/mpd/src";

  mpd' = mpd.overrideAttrs (old: {
    pname = "hifiberry-mpd";
    version = "0.24.13";
    src = sources.mpd;
    patches = (old.patches or [ ]) ++ [
      "${mpdSrc}/debian/patches/0001-alsa-avoid-deadlock-after-cancel-on-pipewire.patch"
    ];
  });

  python = python3.withPackages (_: [ configurator ]);
in
stdenvNoCC.mkDerivation {
  pname = "hifiberry-mpd";
  version = "0.24.13.6";

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/mpd/src";

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ln -s ${mpd'}/bin/mpd $out/bin/mpd
    ln -s ${mpc}/bin/mpc $out/bin/mpc

    install -Dm755 start-mpd.sh $out/bin/start-mpd
    install -Dm755 configure-mpd.py $out/bin/configure-mpd
    install -Dm755 mpd-reconcile $out/bin/mpd-reconcile
    install -Dm755 mpd-set-permissions $out/bin/mpd-set-permissions
    install -Dm644 config/mpd.conf.default $out/share/mpd/mpd.conf
    install -Dm644 players.d/mpd.json $out/etc/audiocontrol/players.d/mpd.json
    install -Dm644 -t $out/share/man/man1 configure-mpd.1 start-mpd.1 mpd-set-permissions.1

    substituteInPlace $out/bin/start-mpd \
      --replace-fail '/usr/bin/configure-mpd' "$out/bin/configure-mpd" \
      --replace-fail '/usr/bin/mpd' "${mpd'}/bin/mpd"
    substituteInPlace $out/bin/configure-mpd \
      --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3' \
      --replace-fail '/usr/share/mpd/mpd.conf' "$out/share/mpd/mpd.conf"
    substituteInPlace $out/bin/mpd-reconcile \
      --replace-fail '/usr/bin/configure-mpd' "$out/bin/configure-mpd" \
      --replace-fail '/usr/bin/mpc' "${mpc}/bin/mpc"
    wrapProgram $out/bin/mpd-reconcile --prefix PATH : ${lib.makeBinPath [ util-linux ]}
    wrapProgram $out/bin/mpd-set-permissions --prefix PATH : ${lib.makeBinPath [ acl ]}
    runHook postInstall
  '';

  passthru.mpd = mpd';

  meta = {
    description = "Music Player Daemon (HiFiBerry build) with HiFiBerryOS wrapper scripts";
    homepage = "https://www.musicpd.org/";
    license = lib.licenses.gpl2Plus;
    mainProgram = "mpd";
    platforms = lib.platforms.linux;
  };
}
