# Development environment for hifiberry-nixos, managed by devenv
# (https://devenv.sh). Run `devenv shell`, or let direnv load it via .envrc.
{ pkgs, ... }:
{
  packages = with pkgs; [
    git
    nixfmt
    nil
    statix
    deadnix
    nix-prefetch-git
    nix-prefetch-github
    prefetch-npm-deps
    zstd
    jq
    python3
  ];

  languages.nix.enable = true;

  scripts = {
    # Build the SD card image for a board: `image rpi5`
    image.exec = ''
      board=''${1:-rpi5}
      nix build --accept-flake-config -L ".#images.$board" "''${@:2}"
      echo "Image: $(readlink -f result)/sd-image/"
    '';
    # Build every package for the host architecture: `build-packages`
    build-packages.exec = ''
      nix build --accept-flake-config -L --no-link --keep-going \
        $(nix flake show --json 2>/dev/null | jq -r --arg s "$(nix eval --impure --raw --expr builtins.currentSystem)" \
          '.packages[$s] | keys[] | select(startswith("image-") | not) | ".#\(.)"')
    '';
    # Evaluate a board's configuration without building: `eval-host rpi5`
    eval-host.exec = ''
      nix eval --accept-flake-config ".#nixosConfigurations.hifiberry-''${1:-rpi5}.config.system.build.toplevel.drvPath"
    '';
    # Update a pinned source in pkgs/sources.nix: `prefetch-source hifiberry acr main`
    prefetch-source.exec = ''
      nix-prefetch-github "$1" "$2" --rev "''${3:-HEAD}" --json
    '';
    fmt.exec = "nixfmt flake.nix $(find pkgs modules hosts -name '*.nix')";
    lint.exec = ''
      statix check .
      deadnix .
    '';
  };

  git-hooks.hooks = {
    nixfmt-rfc-style.enable = true;
    deadnix.enable = true;
    statix.enable = true;
  };

  enterShell = ''
    echo "hifiberry-nixos dev shell"
    echo "  image <board>       build an SD card image (rpi02, rpi3, rpi4, rpi5)"
    echo "  build-packages      build all packages for this machine"
    echo "  eval-host <board>   evaluate a board configuration"
    echo "  fmt / lint          format and lint the Nix code"
  '';
}
