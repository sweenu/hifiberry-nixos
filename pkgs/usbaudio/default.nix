# hifiberry-usbaudio: USB audio gadget (UAC2) support, routing the gadget's
# capture into PipeWire and reporting its state to AudioControl.
{
  lib,
  python3Packages,
  pipewire,
  kmod,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-usbaudio";
  version = "0.1.1";
  pyproject = true;

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/usbaudio/src";

  build-system = [ python3Packages.setuptools ];

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        pipewire
        kmod
      ]
    }"
  ];

  postInstall = ''
    install -Dm644 data/etc/audiocontrol/players.d/usbaudio.json $out/etc/audiocontrol/players.d/usbaudio.json
    install -Dm644 data/etc/configserver/conf.d/usbaudio.json $out/etc/configserver/conf.d/usbaudio.json
    install -Dm644 players.d/usbaudio.json $out/share/hifiberry/players.d/usbaudio.json
    install -Dm644 players.d/icons/usbaudio.svg $out/share/hifiberry/players.d/icons/usbaudio.svg
    rm -rf "''${out:?}/usr"
  '';

  pythonImportsCheck = [ "hifiberry_usbaudio" ];
  doCheck = false;

  meta = {
    description = "USB audio gadget support for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.mit;
    mainProgram = "hifiberry-usbaudio";
    platforms = lib.platforms.linux;
  };
}
