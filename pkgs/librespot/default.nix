# hifiberry-librespot: librespot 0.8.0 (Spotify Connect) built with the features
# and patches of HiFiBerry's package, with the start-librespot wrapper.
{
  lib,
  stdenvNoCC,
  librespot,
  configurator,
  audiocontrol,
  avahi,
  curl,
  systemd,
  nettools,
  procps,
  makeWrapper,
  sources,
}:

let
  librespot' =
    (librespot.override {
      withALSA = true;
      withRodio = true;
      withAvahi = true;
      withMDNS = false;
      tlsBackend = "native-tls";
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          "${sources.hifiberry-librespot}/librespot-patches/0001-fix-connect-report-volume-at-most-VOLUME_UPDATE_DELA.patch"
          "${sources.hifiberry-librespot}/librespot-patches/0002-fix-main-start-at-the-alsa-mixer-s-volume-when-no-in.patch"
        ];
      });
in
stdenvNoCC.mkDerivation {
  pname = "hifiberry-librespot";
  version = "0.8.0.15";

  src = sources.hifiberry-librespot;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ln -s ${librespot'}/bin/librespot $out/bin/librespot
    install -Dm755 start-librespot.sh $out/bin/start-librespot
    install -Dm755 spotify-event.sh $out/bin/spotify-event
    substituteInPlace $out/bin/start-librespot \
      --replace-fail '/usr/bin/config-soundcard' 'config-soundcard' \
      --replace-fail 'EVENT_HANDLER="/usr/bin/spotify-event"' "EVENT_HANDLER=\"$out/bin/spotify-event\"" \
      --replace-fail '/usr/bin/audiocontrol_notify_librespot' '${audiocontrol}/bin/audiocontrol_notify_librespot' \
      --replace-fail 'LIBRESPOT_CMD="/usr/bin/librespot"' 'LIBRESPOT_CMD="${librespot'}/bin/librespot"'
    wrapProgram $out/bin/start-librespot --prefix PATH : ${
      lib.makeBinPath [
        configurator
        avahi
        curl
        systemd
        nettools
        procps
      ]
    }
    install -Dm644 players.d/librespot.json $out/etc/audiocontrol/players.d/librespot.json
    substituteInPlace $out/etc/audiocontrol/players.d/librespot.json \
      --replace-fail '/usr/bin/librespot' '${librespot'}/bin/librespot'
    install -Dm644 ui-players.d/librespot.json $out/share/hifiberry/players.d/librespot.json
    install -Dm644 ui-players.d/icons/librespot.svg $out/share/hifiberry/players.d/icons/librespot.svg
    install -Dm644 icons/spotify.svg $out/share/hifiberry-librespot/icons/spotify.svg
    install -Dm644 -t $out/share/man/man1 debian/*.1
    runHook postInstall
  '';

  passthru.librespot = librespot';

  meta = {
    description = "Librespot Spotify Connect player (HiFiBerry build)";
    homepage = "https://github.com/hifiberry/hifiberry-librespot";
    license = lib.licenses.mit;
    mainProgram = "librespot";
    platforms = lib.platforms.linux;
  };
}
