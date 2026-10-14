# pipewire-api: REST API (port 2716) and pw-param tool for PipeWire routing,
# parameters and volume. Upstream ships no Cargo.lock, so one is kept here.
{
  lib,
  rustPlatform,
  sources,
}:

rustPlatform.buildRustPackage {
  pname = "pipewire-api";
  version = "2.2.0";

  src = sources.pipewire-api;

  cargoLock.lockFile = ./Cargo.lock;
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  cargoBuildFlags = [
    "--bin"
    "pipewire-api"
  ];
  doCheck = false;

  postInstall = ''
    install -Dm644 link-rules.conf volume.conf param-rules.conf -t $out/etc/pipewire-api
    install -Dm644 debian/hifiberry-pipewire.nginx $out/share/pipewire-api/nginx/hifiberry-pipewire.nginx
    install -Dm644 auth/pipewire.json $out/share/hifiberry/auth.d/pipewire.json
    install -Dm644 pipewire-api.1 $out/share/man/man1/pipewire-api.1
    install -Dm644 volume.conf.5 link-rules.conf.5 -t $out/share/man/man5
  '';

  meta = {
    description = "REST API and tools for PipeWire audio control";
    homepage = "https://github.com/hifiberry/pipewire-api";
    license = lib.licenses.mit;
    mainProgram = "pipewire-api";
    platforms = lib.platforms.linux;
  };
}
