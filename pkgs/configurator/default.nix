# hifiberry-configurator: the system configuration service (config-server on
# port 1081) and the config-* command line tools (sound card detection,
# config.txt handling, volume store/restore, Samba mounts, Wi-Fi, ...).
{
  lib,
  python3Packages,
  sources,
  hateeprom,
  alsa-utils,
  i2c-tools,
  systemd,
  util-linux,
}:

python3Packages.buildPythonPackage {
  pname = "hifiberry-configurator";
  version = "2.18.0";
  pyproject = true;

  src = sources.configurator;

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    pyalsaaudio
    cryptography
    netifaces
    hateeprom
    flask
    waitress
    dbus-python
    argcomplete
    bless
    requests
    # I2C device scan (/api/v1/i2c/devices); not declared upstream
    smbus2
  ];

  patches = [ ./nixos-extensions.patch ];

  postPatch = ''
    # requirements.txt lists Debian package names (python3-pyalsaaudio, dbus),
    # which are not pip distributions. Dependencies are provided by Nix above.
    : > requirements.txt

    # NixOS regenerates /boot/firmware/config.txt from the system configuration
    # on every rebuild, so the lines HiFiBerryOS writes at runtime (the detected
    # sound card's dtoverlay and its "# HiFiBerry card:" comment) are kept in a
    # separate file that config.txt includes.
    substituteInPlace configurator/configtxt.py configurator/soundcard_detector.py \
      --replace-fail '/boot/firmware/config.txt' '/boot/firmware/hifiberry.txt'

    # User units are enabled per user (~/.config/systemd/user), not with
    # `systemctl --global`: /etc/systemd/user is read-only on NixOS.
    substituteInPlace configurator/systemd_service.py \
      --replace-fail 'self._run_global_cmd(["enable", service_name])' \
                     'self._run_service_cmd(["enable", service_name], service_name)' \
      --replace-fail 'self._run_global_cmd(["disable", service_name])' \
                     'self._run_service_cmd(["disable", service_name], service_name)'

    # The software volume control ("Softvol") for cards without a hardware
    # mixer is created with alsactl, called by its Debian path.
    substituteInPlace configurator/soundcard.py \
      --replace-fail '/usr/sbin/alsactl' '${alsa-utils}/bin/alsactl'

    substituteInPlace configurator/handlers/system_handler.py \
      --replace-fail "'/usr/sbin/shutdown'" "'/run/current-system/sw/bin/shutdown'" \
      --replace-fail "'/usr/sbin/reboot'" "'/run/current-system/sw/bin/reboot'"
  '';

  # setup.py's data_files use absolute paths (/usr/lib/systemd/...); the NixOS
  # module ships its own units, so only the share/ data is kept.
  postInstall = ''
    install -Dm644 -t $out/share/hifiberry/features.d features.d/*.json
    install -Dm644 -t $out/share/hifiberry/auth.d auth/config.json
    install -Dm644 configserver.json $out/share/hifiberry-configurator/configserver.json
    install -Dm644 debian/hifiberry-config.nginx $out/share/hifiberry-configurator/nginx/hifiberry-config.nginx
    install -Dm644 avahi-services/hifiberry.service $out/share/hifiberry-configurator/avahi/hifiberry.service
    install -Dm644 -t $out/share/man/man1 man/*.1
    install -Dm644 -t $out/share/man/man7 man/*.7
    rm -rf "''${out:?}/usr"
  '';

  # The tools shell out to these.
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        alsa-utils
        i2c-tools
        systemd
        util-linux
      ]
    }"
  ];

  pythonImportsCheck = [ "configurator" ];
  doCheck = false;

  meta = {
    description = "HiFiBerry system configuration service and tools";
    homepage = "https://github.com/hifiberry/configurator";
    license = lib.licenses.mit;
    mainProgram = "config-server";
    platforms = lib.platforms.linux;
  };
}
