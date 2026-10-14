# hifiberry-eeprom: the hateeprom library/CLI (HAT EEPROM access over bit-banged
# I2C with libgpiod) and the pre-compiled EEPROM images for HiFiBerry boards.
{
  lib,
  python3Packages,
  sources,
}:

python3Packages.buildPythonPackage {
  pname = "hateeprom";
  version = "1.3.8";
  pyproject = true;

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/eeprom/src";

  build-system = [ python3Packages.setuptools ];

  # install_requires names "libgpiod", which is not a pip distribution; the
  # bindings come from python3Packages.gpiod.
  postPatch = ''
    substituteInPlace setup.py --replace-fail '"libgpiod",' ""
    rm -rf python/__pycache__
  '';

  dependencies = [ python3Packages.gpiod ];

  postInstall = ''
    install -Dm644 -t $out/share/hifiberry-eeprom eeprom/*.eep eeprom/*.txt
    install -Dm644 man/hateeprom.1 $out/share/man/man1/hateeprom.1
  '';

  pythonImportsCheck = [ "hateeprom" ];
  doCheck = false;

  meta = {
    description = "HiFiBerry HAT EEPROM tools and images";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.mit;
    mainProgram = "hateeprom";
    platforms = lib.platforms.linux;
  };
}
