# roomeq: room equalization REST API (port 10315) with the Rust optimizer, the
# FFT analysis tool and the measurement scripts.
{
  lib,
  stdenv,
  python3Packages,
  rustPlatform,
  alsa-lib,
  alsa-utils,
  sox,
  makeWrapper,
  sources,
}:

let
  optimizer = rustPlatform.buildRustPackage {
    pname = "roomeq-optimizer";
    version = "0.6.0";
    src = sources.roomeq;
    sourceRoot = "${sources.roomeq.name}/src/rust";
    # A copy of the source's Cargo.lock: reading it from the fetched source would
    # need the fetch at evaluation time (import-from-derivation), which
    # `nix flake check` forbids. Keep it in sync when bumping the source.
    cargoLock.lockFile = ./Cargo.lock;
    doCheck = false;
    meta.license = lib.licenses.mit;
  };

  tools = stdenv.mkDerivation {
    pname = "roomeq-tools";
    version = "0.7.4";
    src = sources.roomeq;
    sourceRoot = "${sources.roomeq.name}/src/c";
    buildInputs = [ alsa-lib ];
    nativeBuildInputs = [ makeWrapper ];
    installPhase = ''
      runHook preInstall
      install -Dm755 fft-analyse record-sweep room-measure -t $out/bin
      for s in record-sweep room-measure; do
        wrapProgram $out/bin/$s --prefix PATH : ${
          lib.makeBinPath [
            alsa-utils
            sox
          ]
        }:$out/bin
      done
      runHook postInstall
    '';
    meta.license = lib.licenses.mit;
  };

  signals = stdenv.mkDerivation {
    pname = "roomeq-signals";
    version = "0.7.4";
    src = sources.roomeq;
    nativeBuildInputs = [ (python3Packages.python.withPackages (ps: [ ps.numpy ])) ];
    buildPhase = ''
      mkdir signals
      python3 debian/generate-signals.py signals
    '';
    installPhase = ''
      install -Dm644 -t $out/share/hifiberry/signals signals/*
    '';
    meta.license = lib.licenses.mit;
  };
in
python3Packages.buildPythonApplication {
  pname = "roomeq";
  version = "0.7.4";
  pyproject = true;

  src = sources.roomeq;

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    flask
    flask-cors
    numpy
    scipy
    pyalsaaudio
  ];

  postPatch = ''
    substituteInPlace src/roomeq/rust_optimizer.py \
      --replace-fail '"/usr/bin/roomeq-optimizer"' '"${optimizer}/bin/roomeq-optimizer"'
    substituteInPlace src/roomeq/roomeq_server.py \
      --replace-fail "'/usr/bin/room-measure'" "'${tools}/bin/room-measure'"
  '';

  postInstall = ''
    ln -s ${optimizer}/bin/* $out/bin/
    ln -s ${tools}/bin/* $out/bin/
    mkdir -p $out/share/hifiberry
    ln -s ${signals}/share/hifiberry/signals $out/share/hifiberry/signals
    install -Dm644 debian/hifiberry-roomeq.nginx $out/share/roomeq/nginx/hifiberry-roomeq.nginx
    install -Dm644 auth/roomeq.json $out/share/hifiberry/auth.d/roomeq.json
    install -Dm644 -t $out/share/man/man1 debian/*.1
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        alsa-utils
        sox
      ]
    }"
  ];

  # nixpkgs' flask-cors reports an odd version to the runtime dependency check.
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ "roomeq" ];
  doCheck = false;

  passthru = {
    inherit optimizer tools signals;
  };

  meta = {
    description = "HiFiBerry room equalization service";
    homepage = "https://github.com/hifiberry/roomeq";
    license = lib.licenses.mit;
    mainProgram = "roomeq-server";
    platforms = lib.platforms.linux;
  };
}
