# nowplaying-sdl: SDL2 now-playing display for a locally attached screen.
{
  lib,
  python3Packages,
  SDL2,
  SDL2_ttf,
  SDL2_image,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "nowplaying-sdl";
  version = "1.0.0";
  pyproject = true;

  src = sources.nowplaying-sdl;

  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.pysdl2 ];
  buildInputs = [
    SDL2
    SDL2_ttf
    SDL2_image
  ];

  makeWrapperArgs = [
    "--set PYSDL2_DLL_PATH ${
      lib.makeLibraryPath [
        SDL2
        SDL2_ttf
        SDL2_image
      ]
    }"
  ];

  postInstall = ''
    install -Dm644 nowplaying_sdl.conf $out/share/nowplaying-sdl/nowplaying_sdl.conf
  '';

  pythonImportsCheck = [ "nowplaying_sdl" ];
  doCheck = false;

  meta = {
    description = "SDL2-based now playing display for HiFiBerryOS";
    homepage = "https://github.com/hifiberry/nowplaying-sdl";
    license = lib.licenses.mit;
    mainProgram = "nowplaying-sdl";
    platforms = lib.platforms.linux;
  };
}
