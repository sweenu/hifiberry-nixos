# hifiberry-auth: the authentication/authorization gateway behind nginx's
# auth_request. Classifies API calls as ok/risky from /etc/hifiberry/auth.d.
{
  lib,
  python3Packages,
  sources,
}:

python3Packages.buildPythonApplication {
  pname = "hifiberry-auth";
  version = "0.2.2";
  pyproject = true;

  src = sources.hifiberry-auth;

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    flask
    waitress
    argon2-cffi
  ];

  postInstall = ''
    install -Dm644 nginx/00-verify.conf $out/share/hifiberry-auth/nginx/00-verify.conf
    install -Dm644 nginx/hifiberry-auth.nginx $out/share/hifiberry-auth/nginx/hifiberry-auth.nginx
  '';

  pythonImportsCheck = [ "hifiberry_auth" ];
  doCheck = false;

  meta = {
    description = "HiFiBerryOS authentication gateway";
    homepage = "https://github.com/hifiberry/hifiberry-auth";
    license = lib.licenses.mit;
    mainProgram = "hifiberry-auth";
    platforms = lib.platforms.linux;
  };
}
