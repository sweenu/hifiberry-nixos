# hifiberry-vu-meter: captures audio levels from PipeWire and streams them over
# WebSocket (port 2717) for the web UI's VU meter.
{
  lib,
  rustPlatform,
  pkg-config,
  pipewire,
  sources,
}:

rustPlatform.buildRustPackage {
  pname = "hifiberry-vu-meter";
  version = "0.1.4";

  src = sources.vu-meter;
  # A copy of the source's Cargo.lock: reading it from the fetched source would
  # need the fetch at evaluation time (import-from-derivation), which
  # `nix flake check` forbids. Keep it in sync when bumping the source.
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];
  buildInputs = [ pipewire ];

  doCheck = false;

  postInstall = ''
    install -Dm644 package-files/etc/nginx/hifiberry-vu-meter.nginx $out/share/hifiberry-vu-meter/nginx/hifiberry-vu-meter.nginx
    install -Dm644 package-files/etc/hifiberry/auth.d/vu-meter.json $out/share/hifiberry/auth.d/vu-meter.json
  '';

  meta = {
    description = "HiFiBerry VU meter service";
    homepage = "https://github.com/hifiberry/vu-meter";
    license = lib.licenses.mit;
    mainProgram = "vu-meter-service";
    platforms = lib.platforms.linux;
  };
}
