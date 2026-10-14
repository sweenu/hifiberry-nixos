# HiFiBerry AudioControl (acr): the central player/volume/library daemon and the
# metadata daemon, built exactly like hifiberry-audiocontrol's debian/rules:
# the workspace (including the audiocontrol-metadata binary) is built with
# default features, and the `audiocontrol` binary separately with the
# `metadata` feature off so the two daemons do not both run the metadata code.
{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  dbus,
  alsa-lib,
  python3,
  sources,
  # Path to a secrets.txt in the format of secrets.txt.sample. HiFiBerry bakes
  # its Last.fm, TheAudioDB and Spotify OAuth proxy credentials into the binary
  # at build time; without them scrobbling, TheAudioDB lookups and the Spotify
  # account link do not work. Everything else does.
  secretsFile ? null,
}:

rustPlatform.buildRustPackage {
  pname = "hifiberry-audiocontrol";
  version = "0.23.6";

  src = sources.acr;

  cargoLock.lockFile = "${sources.acr}/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    python3
  ];
  buildInputs = [
    openssl
    dbus
    alsa-lib
  ];

  # jemalloc bakes the page size in at build time; 16 KiB pages cover both the
  # Pi 4 (4 KiB) and the Pi 5 (16 KiB) kernels. See .cargo/config.toml upstream.
  env.JEMALLOC_SYS_WITH_LG_PAGE = "14";

  postPatch = lib.optionalString (secretsFile != null) ''
    cp ${secretsFile} secrets.txt
  '';

  buildPhase = ''
    runHook preBuild
    cargo build --release --offline -j "$NIX_BUILD_CORES" --workspace --exclude audiocontrol
    cargo build --release --offline -j "$NIX_BUILD_CORES" -p audiocontrol --no-default-features --features alsa
    runHook postBuild
  '';

  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin target/release/audiocontrol target/release/audiocontrol-metadata
    for tool in target/release/audiocontrol_*; do
      [ -f "$tool" ] && [ -x "$tool" ] && install -Dm755 -t $out/bin "$tool"
    done
    install -Dm755 example/python/audiocontrol_nowplaying.py $out/bin/audiocontrol_nowplaying
    install -Dm755 scripts/pause-all $out/bin/pause-all
    patchShebangs $out/bin

    install -Dm644 -t $out/etc/audiocontrol configs/audiocontrol.json configs/logging.json configs/metadata.json configs/genres.json
    install -Dm644 -t $out/etc/audiocontrol/players.d configs/players.d/mpris.json
    install -Dm644 debian/hifiberry-audiocontrol.nginx $out/share/hifiberry-audiocontrol/nginx/hifiberry-audiocontrol.nginx
    install -Dm644 -t $out/share/hifiberry/auth.d auth.d/audiocontrol-auth.json auth.d/audiocontrol-metadata-auth.json
    runHook postInstall
  '';

  meta = {
    description = "HiFiBerry AudioControl: player management, volume and library daemon";
    homepage = "https://github.com/hifiberry/acr";
    license = lib.licenses.mit;
    mainProgram = "audiocontrol";
    platforms = lib.platforms.linux;
  };
}
