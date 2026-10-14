# hifiberry-input-processor: the analog input processor LADSPA plugin (RIAA
# phono EQ, subsonic filter, declick, notch) loaded by a PipeWire filter chain,
# and the riaa_process command line tool.
{
  lib,
  stdenv,
  ladspa-header,
  libsndfile,
  sources,
}:

stdenv.mkDerivation {
  pname = "hifiberry-input-processor";
  version = "1.3.1";

  src = sources.input-processor;

  buildInputs = [
    ladspa-header
    libsndfile
  ];

  buildFlags = [
    "ladspa"
    "riaa_process"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 riaa.so $out/lib/ladspa/riaa.so
    install -Dm755 riaa_process $out/bin/riaa_process
    install -Dm644 pipewire/90-input-processor.conf $out/share/hifiberry-input-processor/pipewire/90-input-processor.conf
    install -Dm644 pipewire/99-input-processor-autoconnect.conf $out/share/hifiberry-input-processor/wireplumber/99-input-processor-autoconnect.conf
    install -Dm644 README.md TEST-PLUGIN.md -t $out/share/doc/hifiberry-input-processor
    runHook postInstall
  '';

  meta = {
    description = "Analog input processor LADSPA plugin with RIAA phono equalization";
    homepage = "https://github.com/hifiberry/input-processor";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
