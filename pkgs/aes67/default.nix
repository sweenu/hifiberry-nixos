# hifiberry-aes67: AES67 receiver (Dante/AES67 streams into PipeWire) with a
# discovery agent API on port 1083, as the "aes67" player.
{
  lib,
  python3Packages,
  pipewire,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-aes67";
  version = "0.3.6";
  pyproject = true;

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/aes67/src";

  build-system = [ python3Packages.setuptools ];

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ pipewire ]}" ];

  postInstall = ''
    install -Dm644 data/etc/audiocontrol/players.d/aes67.json $out/etc/audiocontrol/players.d/aes67.json
    install -Dm644 data/etc/configserver/conf.d/aes67.json $out/etc/configserver/conf.d/aes67.json
    install -Dm644 data/etc/hifiberry/auth.d/aes67.json $out/share/hifiberry/auth.d/aes67.json
    install -Dm644 players.d/aes67.json $out/share/hifiberry/players.d/aes67.json
    install -Dm644 players.d/icons/aes67.svg $out/share/hifiberry/players.d/icons/aes67.svg
    install -Dm644 debian/hifiberry-aes67.nginx $out/share/hifiberry-aes67/nginx/hifiberry-aes67.nginx
    rm -rf "''${out:?}/usr"
  '';

  pythonImportsCheck = [ "hifiberry_aes67" ];
  doCheck = false;

  meta = {
    description = "AES67 receiver for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.mit;
    mainProgram = "hifiberry-aes67";
    platforms = lib.platforms.linux;
  };
}
