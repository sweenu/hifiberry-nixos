# hifiberry-raat: Roon Ready (RAAT) player. The RAAT SDK is proprietary and the
# hifiberry/raat repository is private, so the binaries are taken from the
# package HiFiBerry publishes in its Debian repository and patched to run on
# NixOS; the wrapper scripts come from hifiberry-os. aarch64 only.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  alsa-lib,
  glib,
  python3,
  configurator,
  avahi,
  procps,
  makeWrapper,
  sources,
}:

let
  version = "1.1.43.25";
  deb = fetchurl {
    url = "http://debianrepo.hifiberry.com/pool/trixie/main/h/hifiberry-raat/hifiberry-raat_${version}_arm64.deb";
    hash = "sha256-Lx9rEAEgGyfoZn3EXVDbqE3522D2lfTa+Wa6ybE/P0Y=";
  };
  python = python3.withPackages (_: [ configurator ]);
in
stdenv.mkDerivation {
  pname = "hifiberry-raat";
  inherit version;

  src = deb;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    glib
    (lib.getLib stdenv.cc.cc)
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src unpacked
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    # The RAAT binaries only; the scripts around them are taken from hifiberry-os.
    for f in unpacked/usr/bin/*; do
      case "$(basename "$f")" in
        start-raat|configure-raat) ;;
        *) install -Dm755 "$f" $out/bin/ ;;
      esac
    done

    raatsrc=${sources.hifiberry-os}/packages/raat/src
    install -Dm755 $raatsrc/start-raat.sh $out/bin/start-raat
    sed "s/###MYVERSION###/${version}/g" $raatsrc/configure-raat.py > $out/bin/configure-raat
    chmod 755 $out/bin/configure-raat
    substituteInPlace $out/bin/configure-raat --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'
    substituteInPlace $out/bin/start-raat \
      --replace-fail '/usr/bin/config-soundcard' 'config-soundcard' \
      --replace-fail '/usr/bin/configure-raat' "$out/bin/configure-raat" \
      --replace-fail '/usr/bin/raat_app' "$out/bin/raat_app"
    wrapProgram $out/bin/start-raat --prefix PATH : ${
      lib.makeBinPath [
        configurator
        avahi
        procps
      ]
    }
    install -Dm644 $raatsrc/players.d/raat.json $out/etc/audiocontrol/players.d/raat.json
    runHook postInstall
  '';

  meta = {
    description = "Roon Ready (RAAT) player for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "raat_app";
    platforms = [ "aarch64-linux" ];
  };
}
