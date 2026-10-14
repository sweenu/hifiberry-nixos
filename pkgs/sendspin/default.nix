# hifiberry-sendspin: sendspind, the Music Assistant (Sendspin protocol) player.
# The CMake build fetches sendspin-cpp and its libraries with FetchContent; the
# pinned sources are handed to it instead.
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  alsa-lib,
  curl,
  nlohmann_json,
  avahi-compat,
  sources,
}:

stdenv.mkDerivation {
  pname = "hifiberry-sendspin";
  version = "0.1.7";

  src = sources.sendspin;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    alsa-lib
    curl
    nlohmann_json
    avahi-compat
  ];

  cmakeFlags = [ "-DFETCHCONTENT_FULLY_DISCONNECTED=ON" ];

  # The dependencies' own CMake code writes into their source trees (micro-opus
  # stages opus' sources), so hand FetchContent writable copies.
  preConfigure = ''
    deps=$NIX_BUILD_TOP/deps
    mkdir -p $deps
    cp -r --no-preserve=mode,ownership ${sources.sendspin-cpp} $deps/sendspin
    cp -r --no-preserve=mode,ownership ${sources.arduinojson} $deps/arduinojson
    cp -r --no-preserve=mode,ownership ${sources.micro-flac} $deps/micro_flac
    cp -r --no-preserve=mode,ownership ${sources.micro-opus} $deps/micro_opus
    cp -r --no-preserve=mode,ownership ${sources.ixwebsocket} $deps/ixwebsocket
    cmakeFlagsArray+=(
      "-DFETCHCONTENT_SOURCE_DIR_SENDSPIN=$deps/sendspin"
      "-DFETCHCONTENT_SOURCE_DIR_ARDUINOJSON=$deps/arduinojson"
      "-DFETCHCONTENT_SOURCE_DIR_MICRO_FLAC=$deps/micro_flac"
      "-DFETCHCONTENT_SOURCE_DIR_MICRO_OPUS=$deps/micro_opus"
      "-DFETCHCONTENT_SOURCE_DIR_IXWEBSOCKET=$deps/ixwebsocket"
    )
  '';

  doCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 sendspind $out/bin/sendspind
    install -Dm755 ../scripts/start-sendspin.sh $out/bin/start-sendspin
    install -Dm644 ../data/etc/audiocontrol/players.d/sendspin.json $out/etc/audiocontrol/players.d/sendspin.json
    install -Dm644 ../data/usr/share/hifiberry/players.d/sendspin.json $out/share/hifiberry/players.d/sendspin.json
    install -Dm644 ../data/usr/share/hifiberry/players.d/icons/sendspin.svg $out/share/hifiberry/players.d/icons/sendspin.svg
    install -Dm644 ../data/etc/configserver/conf.d/sendspin.json $out/etc/configserver/conf.d/sendspin.json
    substituteInPlace $out/bin/start-sendspin \
      --replace-fail '/usr/bin/sendspind' "$out/bin/sendspind" \
      --replace-fail '/usr/bin/config-soundcard' 'config-soundcard'
    runHook postInstall
  '';

  meta = {
    description = "Sendspin (Music Assistant) player for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/sendspin";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "sendspind";
    platforms = lib.platforms.linux;
  };
}
