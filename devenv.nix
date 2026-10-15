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
    # Build the example SD card image for a board: `image rpi4`
    image.exec = ''
      board=''${1:-rpi4}
      nix build --accept-flake-config -L ".#nixosConfigurations.example-$board.config.system.build.sdImage" "''${@:2}"
      echo "Image: $(readlink -f result)/sd-image/"
    '';
    # Build every package for the host architecture: `build-packages`
    build-packages.exec = ''
      nix build --accept-flake-config -L --no-link --keep-going \
        $(nix flake show --json 2>/dev/null | jq -r --arg s "$(nix eval --impure --raw --expr builtins.currentSystem)" \
          '.packages[$s] | keys[] | ".#\(.)"')
    '';
    # Evaluate the example configuration for a board without building: `eval-example rpi4`
    eval-example.exec = ''
      nix eval --accept-flake-config ".#nixosConfigurations.example-''${1:-rpi4}.config.system.build.toplevel.drvPath"
    '';
    # Update a pinned source in pkgs/sources.nix: `prefetch-source hifiberry acr main`
    prefetch-source.exec = ''
      nix-prefetch-github "$1" "$2" --rev "''${3:-HEAD}" --json
    '';
    fmt.exec = "nixfmt $(find . -name '*.nix' -not -path './.devenv/*')";
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
    echo "  image <board>         build the example SD card image (rpi02, rpi3, rpi4, rpi5)"
    echo "  build-packages        build all packages for this machine"
    echo "  eval-example <board>  evaluate the example configuration for a board"
    echo "  fmt / lint          format and lint the Nix code"
  '';
}
