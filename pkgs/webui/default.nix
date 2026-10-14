# hifiberry-webui: the Vue 3 single-page web interface (hbos-ui), built with
# vite and served by nginx from share/hifiberry/webui.
{
  lib,
  stdenv,
  buildNpmPackage,
  nodejs_22,
  autoPatchelfHook,
  sources,
}:

buildNpmPackage {
  pname = "hifiberry-webui";
  version = "0.27.1";

  src = sources.hbos-ui;
  nodejs = nodejs_22;

  npmDepsHash = "sha256-8wCmvOdW46XAvcNYVpvH64wmVu9s1ks1rUP9DhK4wR4=";

  # sass-embedded ships a prebuilt dart binary that cannot run in the Nix
  # sandbox without its interpreter being patched.
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  dontAutoPatchelf = true;

  preBuild = ''
    for dart in node_modules/sass-embedded-linux-*/dart-sass/src/dart; do
      case "$dart" in *musl*) continue ;; esac
      [ -f "$dart" ] && autoPatchelf "$dart"
    done
  '';

  npmBuildScript = "build-only";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/hifiberry/webui
    cp -r dist/* $out/share/hifiberry/webui/
    install -Dm644 debian/package-files/etc/nginx/hifiberry-webui.nginx $out/share/hifiberry-webui/nginx/hifiberry-webui.nginx
    install -Dm644 debian/package-files/etc/nginx/sites-available/hifiberry-webui $out/share/hifiberry-webui/nginx/hifiberry-webui
    runHook postInstall
  '';

  meta = {
    description = "HiFiBerryOS web user interface";
    homepage = "https://github.com/hifiberry/hbos-ui";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
