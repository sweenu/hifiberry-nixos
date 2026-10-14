# hifiberry-bluetooth: BlueZ agent that manages incoming Bluetooth audio
# connections (pairing, A2DP sink) and exposes them to AudioControl.
{
  lib,
  python3Packages,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-bluetooth";
  version = "1.0.8";
  pyproject = true;

  src = sources.hbos-bluetooth;

  build-system = [ python3Packages.setuptools ];

  postPatch = ''
    # requirements.txt names "gobject"/"dbus-python" as pip distributions;
    # the real dependencies are provided below.
    : > requirements.txt
  '';

  dependencies = with python3Packages; [
    dbus-python
    pygobject3
    watchdog
    requests
  ];

  postInstall = ''
    install -Dm644 debian/bluetooth.json $out/etc/audiocontrol/players.d/bluetooth.json
    install -Dm644 debian/hifiberry-btaudio.nginx $out/share/hifiberry-bluetooth/nginx/hifiberry-btaudio.nginx
    install -Dm644 man/hifiberry-bluetooth.1 $out/share/man/man1/hifiberry-bluetooth.1
    rm -rf "''${out:?}/usr"
  '';

  pythonImportsCheck = [ "hifiberry_bluetooth" ];
  doCheck = false;

  meta = {
    description = "HiFiBerry Bluetooth audio service";
    homepage = "https://github.com/hifiberry/hbos-bluetooth";
    license = lib.licenses.mit;
    mainProgram = "hifiberry-bluetooth";
    platforms = lib.platforms.linux;
  };
}
