# ladspa-speakereq: 2x2 speaker equalization LADSPA plugin (20-band parametric
# EQ per channel, crossbar routing, delay) loaded by a PipeWire filter chain.
{
  lib,
  stdenv,
  ladspa-header,
  sources,
}:

stdenv.mkDerivation {
  pname = "ladspa-speakereq";
  version = "1.2";

  src = sources.speakereq;

  buildInputs = [ ladspa-header ];

  buildFlags = [ "ladspa" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 speakereq2x2.so $out/lib/ladspa/speakereq2x2.so
    install -Dm644 pipewire/90-speakereq.conf $out/share/ladspa-speakereq/pipewire/90-speakereq.conf
    install -Dm644 pipewire/99-force-effect-filter.conf $out/share/ladspa-speakereq/wireplumber/99-force-effect-filter.conf
    install -Dm644 speakereq2x2.1 $out/share/man/man1/speakereq2x2.1
    runHook postInstall
  '';

  meta = {
    description = "Speaker equalization LADSPA plugin";
    homepage = "https://github.com/hifiberry/speakereq";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
