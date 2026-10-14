# hifiberry-squeezelite: squeezelite at the commit HiFiBerryOS builds, with the
# start-squeezelite wrapper that reads its settings from the config database.
{
  lib,
  stdenvNoCC,
  squeezelite,
  configurator,
  systemd,
  nettools,
  makeWrapper,
  sources,
}:

let
  squeezelite' = squeezelite.overrideAttrs (_old: {
    version = "2.0.0.1566";
    src = sources.squeezelite;
  });
in
stdenvNoCC.mkDerivation {
  pname = "hifiberry-squeezelite";
  version = "2.0.0.1566";

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/squeezelite/src";

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ln -s ${squeezelite'}/bin/squeezelite $out/bin/squeezelite
    install -Dm755 start-squeezelite $out/bin/start-squeezelite
    substituteInPlace $out/bin/start-squeezelite \
      --replace-fail '/usr/bin/config-soundcard' 'config-soundcard' \
      --replace-fail '/usr/bin/squeezelite' '${squeezelite'}/bin/squeezelite'
    wrapProgram $out/bin/start-squeezelite --prefix PATH : ${
      lib.makeBinPath [
        configurator
        systemd
        nettools
      ]
    }
    install -Dm644 players.d/squeezelite.json $out/etc/audiocontrol/players.d/squeezelite.json
    install -Dm644 ui-players.d/squeezelite.json $out/share/hifiberry/players.d/squeezelite.json
    install -Dm644 ui-players.d/icons/squeezelite.svg $out/share/hifiberry/players.d/icons/squeezelite.svg
    install -Dm644 -t $out/share/man/man1 man/*.1
    runHook postInstall
  '';

  passthru.squeezelite = squeezelite';

  meta = {
    description = "Squeezelite (LMS/Squeezebox player) for HiFiBerryOS";
    homepage = "https://github.com/ralph-irving/squeezelite";
    license = lib.licenses.gpl3Plus;
    mainProgram = "squeezelite";
    platforms = lib.platforms.linux;
  };
}
