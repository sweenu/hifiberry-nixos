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
  cargoLock.lockFile = "${sources.songcompare}/Cargo.lock";

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
