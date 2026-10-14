# hifiberry-acr-webmcp: a Model Context Protocol (MCP) server over HTTP exposing
# AudioControl's API to AI assistants (port 13180, /api/acr-webmcp/).
{
  lib,
  stdenvNoCC,
  python3,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "hifiberry-acr-webmcp";
  version = "0.1.9";

  src = sources.hifiberry-os;
  sourceRoot = "${sources.hifiberry-os.name}/packages/acr-webmcp/src";

  buildInputs = [ python3 ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 acr-webmcp $out/bin/acr-webmcp
    install -Dm644 debian/hifiberry-acr-webmcp.nginx $out/share/hifiberry-acr-webmcp/nginx/hifiberry-acr-webmcp.nginx
    patchShebangs $out/bin
    runHook postInstall
  '';

  meta = {
    description = "MCP server for HiFiBerry AudioControl";
    homepage = "https://github.com/hifiberry/hifiberry-os";
    license = lib.licenses.mit;
    mainProgram = "acr-webmcp";
    platforms = lib.platforms.linux;
  };
}
