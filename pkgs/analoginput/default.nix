# hifiberry-analoginput: links the sound card's analog input to the output in
# PipeWire (plain analog pass-through).
{
  lib,
  python3Packages,
  pipewire,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-analoginput";
  version = "1.0.0";
  pyproject = true;

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/analoginput/src";

  build-system = [ python3Packages.setuptools ];

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ pipewire ]}" ];

  postInstall = ''
    rm -rf "''${out:?}/usr"
  '';

  pythonImportsCheck = [ "hifiberry_analoginput" ];
  doCheck = false;

  meta = {
    description = "Analog input pass-through for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.mit;
    mainProgram = "hifiberry-analoginput";
    platforms = lib.platforms.linux;
  };
}
