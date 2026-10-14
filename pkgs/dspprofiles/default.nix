# hifiberry-dspprofiles: SigmaStudio DSP profiles for the Beocreate, DAC+ DSP and
# DSP add-on boards, plus the speaker presets and the parse_sigmastudio_params tool.
{
  lib,
  stdenvNoCC,
  python3,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "hifiberry-dspprofiles";
  version = "1.1.1";

  src = sources.dspprofiles;

  nativeBuildInputs = [ python3 ];

  # The Makefile only wraps dpkg-buildpackage.
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/hifiberry/dspprofiles \
      beocreate/beocreate-universal-11.xml \
      dac+dsp/dacdsp-15.xml \
      dspaddon/dsp-addon-96-14.xml \
      dspaddon/dsp-addon-96-15.xml
    install -Dm644 -t $out/share/hifiberry/speaker-presets speaker-presets/*.json
    install -Dm755 metadata-generator/parse_params.py $out/bin/parse_sigmastudio_params
    install -Dm644 debian/manpages/parse_sigmastudio_params.1 $out/share/man/man1/parse_sigmastudio_params.1
    patchShebangs $out/bin
    runHook postInstall
  '';

  meta = {
    description = "HiFiBerry DSP audio profiles";
    homepage = "https://github.com/hifiberry/dspprofiles";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
