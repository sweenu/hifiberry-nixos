# hifiberry-analog-recognition: identifies tracks on the analog input with
# songrec and reports play/stop from the signal level, as the "analog" player.
{
  lib,
  rustPlatform,
  pkg-config,
  pipewire,
  songrec,
  configurator,
  makeWrapper,
  sources,
}:

rustPlatform.buildRustPackage {
  pname = "hifiberry-analog-recognition";
  version = "0.4.2";

  src = sources.analog-recognition;
  # A copy of the source's Cargo.lock: reading it from the fetched source would
  # need the fetch at evaluation time (import-from-derivation), which
  # `nix flake check` forbids. Keep it in sync when bumping the source.
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    makeWrapper
  ];
  buildInputs = [ pipewire ];

  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/analog-recognition --prefix PATH : ${
      lib.makeBinPath [
        songrec
        pipewire
        configurator
      ]
    }
    install -Dm644 package-files/etc/analog-recognition/config.toml $out/etc/analog-recognition/config.toml
    install -Dm644 package-files/etc/audiocontrol/players.d/analog.json $out/etc/audiocontrol/players.d/analog.json
    install -Dm644 package-files/etc/hifiberry/players.d/analog.json $out/share/hifiberry/players.d/analog.json
    install -Dm644 package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg $out/share/hifiberry/players.d/icons/analog.svg
  '';

  meta = {
    description = "HiFiBerry analog input recognition service";
    homepage = "https://github.com/hifiberry/analog-recognition";
    license = lib.licenses.mit;
    mainProgram = "analog-recognition";
    platforms = lib.platforms.linux;
  };
}
