# hifiberry-shairport: AirPlay via shairport-sync, built twice like HiFiBerry's
# package (an AirPlay 2 build as `shairport-airplay2` and a classic build as
# `shairport`), with nqptp, the metadata reader and the wrapper scripts.
{
  lib,
  stdenv,
  stdenvNoCC,
  shairport-sync,
  nqptp,
  autoreconfHook,
  configurator,
  curl,
  systemd,
  nettools,
  makeWrapper,
  sources,
}:

let
  mkShairport =
    airplay2:
    (shairport-sync.override {
      enableAirplay2 = airplay2;
      enableAvahi = true;
      enableAlsa = true;
      enableMetadata = true;
      enableDbus = true;
      enableMpris = true;
      enableMqttClient = false;
      enableSoxr = false;
      enablePipe = false;
      enableStdout = false;
      enablePulse = false;
      enablePipewire = false;
      enableAo = false;
      enableJack = false;
      enableSoundio = false;
      enableSndio = false;
      enableAlac = false;
      enableConvolution = false;
      enableTinySVCmDNS = false;
    }).overrideAttrs
      (old: {
        version = "5.5.0-unstable-2026";
        src = sources.shairport-sync;
        configureFlags = old.configureFlags ++ [ "--with-metadata-multicast" ];
        # HiFiBerryOS runs shairport in the player's user session but talks to
        # the system bus like the Debian package does; keep upstream behaviour.
        postPatch = "";
      });

  shairportAirplay2 = mkShairport true;
  shairportLegacy = mkShairport false;

  nqptp' = nqptp.overrideAttrs (_old: {
    version = "1.2.6";
    src = sources.nqptp;
    configureFlags = [ "--with-systemd-startup" ];
  });

  metadataReader = stdenv.mkDerivation {
    pname = "shairport-sync-metadata-reader";
    version = "0-unstable-2025";
    src = sources.shairport-sync-metadata-reader;
    nativeBuildInputs = [ autoreconfHook ];
    meta.license = lib.licenses.mit;
  };
in
stdenvNoCC.mkDerivation {
  pname = "hifiberry-shairport";
  version = "5.5.0.1";

  src = sources.hifiberry-shairport;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ln -s ${shairportAirplay2}/bin/shairport-sync $out/bin/shairport-airplay2
    ln -s ${shairportLegacy}/bin/shairport-sync $out/bin/shairport
    ln -s ${nqptp'}/bin/nqptp $out/bin/nqptp
    ln -s ${metadataReader}/bin/shairport-sync-metadata-reader $out/bin/shairport-sync-metadata-reader

    install -Dm755 start-shairport.sh $out/bin/start-shairport
    install -Dm755 start-nqptp.sh $out/bin/start-nqptp
    install -Dm755 shairport-event.sh $out/bin/shairport-event
    ln -s shairport-event $out/bin/shairport-event-start
    ln -s shairport-event $out/bin/shairport-event-stop
    install -Dm755 shairport-metadata-example.sh $out/bin/shairport-metadata-example
    install -Dm755 shairport-playpause.sh $out/bin/shairport-playpause

    substituteInPlace $out/bin/start-shairport \
      --replace-fail '/usr/bin/config-soundcard' 'config-soundcard' \
      --replace-fail 'SHAIRPORT_CMD="/usr/bin/shairport"' "SHAIRPORT_CMD=\"$out/bin/shairport\"" \
      --replace-fail 'SHAIRPORT_CMD="/usr/bin/shairport-airplay2"' "SHAIRPORT_CMD=\"$out/bin/shairport-airplay2\""
    substituteInPlace $out/bin/start-nqptp --replace-fail '/usr/bin/nqptp' "$out/bin/nqptp"
    wrapProgram $out/bin/start-shairport --prefix PATH : ${
      lib.makeBinPath [
        configurator
        curl
        systemd
        nettools
      ]
    }

    install -Dm644 shairport-sync.conf.default $out/share/hifiberry-shairport/shairport-sync.conf.default
    install -Dm644 players.d/shairport.json $out/etc/audiocontrol/players.d/shairport.json
    install -Dm644 ui-players.d/shairport.json $out/share/hifiberry/players.d/shairport.json
    install -Dm644 ui-players.d/icons/shairport.svg $out/share/hifiberry/players.d/icons/shairport.svg
    install -Dm644 icons/airplay.svg $out/share/hifiberry-shairport/icons/airplay.svg
    install -Dm644 -t $out/share/man/man1 man/*.1
    runHook postInstall
  '';

  passthru = {
    airplay2 = shairportAirplay2;
    legacy = shairportLegacy;
    nqptp = nqptp';
    inherit metadataReader;
  };

  meta = {
    description = "AirPlay receiver (shairport-sync) for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/hifiberry-shairport";
    license = lib.licenses.mit;
    mainProgram = "shairport-airplay2";
    platforms = lib.platforms.linux;
  };
}
