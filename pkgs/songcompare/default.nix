# songcompare: A/B listening comparison tool.
{
  lib,
  rustPlatform,
  pkg-config,
  alsa-lib,
  sources,
}:

rustPlatform.buildRustPackage {
  pname = "hifiberry-songcompare";
  version = "1.0.1";

  src = sources.songcompare;
  # A copy of the source's Cargo.lock: reading it from the fetched source would
  # need the fetch at evaluation time (import-from-derivation), which
  # `nix flake check` forbids. Keep it in sync when bumping the source.
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  doCheck = false;

  meta = {
    description = "A/B listening comparison tool";
    homepage = "https://github.com/hifiberry/songcompare";
    license = lib.licenses.mit;
    mainProgram = "songcompare";
    platforms = lib.platforms.linux;
  };
}
