# hifiberry-dsp: DSP toolkit (dsptoolkit, sigmatcpserver with its REST API,
# dsp-install-profile, ...) for the HiFiBerry DSP boards.
{
  lib,
  python3Packages,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-dsp";
  version = "1.5.5";
  pyproject = true;

  src = sources.hifiberry-dsp;
  sourceRoot = "${sources.hifiberry-dsp.name}/src";

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    xmltodict
    spidev
    pyalsaaudio
    requests
    flask
    waitress
  ];

  postInstall = ''
    install -Dm755 bin/dspdac-reset bin/mergeparameters bin/optimizer-client bin/spdifclockgen -t $out/bin
    install -Dm644 ../auth/dsptoolkit.json $out/share/hifiberry/auth.d/dsptoolkit.json
    install -Dm644 ../debian/hifiberry-sigmatcp.nginx $out/share/hifiberry-dsp/nginx/hifiberry-sigmatcp.nginx
    install -Dm644 ../debian/hifiberry-dsp.udev $out/lib/udev/rules.d/60-hifiberry-dsp.rules
    install -Dm644 -t $out/share/man/man1 ../man/man1/*.1
  '';

  pythonImportsCheck = [ "hifiberrydsp" ];
  doCheck = false;

  meta = {
    description = "HiFiBerry DSP toolkit";
    homepage = "https://github.com/hifiberry/hifiberry-dsp";
    license = lib.licenses.mit;
    mainProgram = "dsptoolkit";
    platforms = lib.platforms.linux;
  };
}
