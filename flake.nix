{
  description = "HiFiBerryOS on NixOS: every HiFiBerryOS component as a Nix package, NixOS modules, and SD card images for Raspberry Pi";

  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    # Raspberry Pi kernel (with the HiFiBerry sound card drivers and device tree
    # overlays), firmware, bootloader and config.txt handling for NixOS.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    # Follow nixos-raspberrypi's nixpkgs so its binary cache applies.
    nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-raspberrypi,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
      mkPackages = pkgs: import ./pkgs { inherit pkgs; };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "hifiberry-raat" ];
        };

      boards = [
        "rpi02"
        "rpi3"
        "rpi4"
        "rpi5"
      ];

      mkHost =
        board:
        nixos-raspberrypi.lib.nixosSystem {
          specialArgs = {
            inherit nixos-raspberrypi;
            hifiberry-nixos = self;
          };
          modules = [
            self.nixosModules.default
            ./modules/sd-image.nix
            ./hosts/${board}.nix
          ];
        };

      # The same system as a QEMU virtual machine, for trying it on a computer.
      mkVm =
        system:
        nixpkgs.lib.nixosSystem {
          specialArgs.hifiberry-nixos = self;
          modules = [
            self.nixosModules.default
            ./hosts/vm.nix
            { nixpkgs.hostPlatform = system; }
          ];
        };
      vmName = system: "hifiberry-vm-${lib.head (lib.splitString "-" system)}";
    in
    {
      nixosModules = {
        # The HiFiBerryOS modules. Needs `nixos-raspberrypi` in specialArgs (the
        # nixos-raspberrypi.lib.nixosSystem helper does that) for the firmware
        # configuration.
        hifiberry = import ./modules;
        default = self.nixosModules.hifiberry;
        sd-image = import ./modules/sd-image.nix;
      };

      overlays.default = final: _prev: {
        hifiberry = mkPackages final;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          hb = mkPackages pkgs;
          pkgSet = lib.filterAttrs (
            _: v: lib.isDerivation v && lib.meta.availableOn pkgs.stdenv.hostPlatform v
          ) (builtins.removeAttrs hb [ "sources" ]);
        in
        pkgSet
        // lib.optionalAttrs (system == "aarch64-linux") (
          lib.listToAttrs (
            map (
              b:
              lib.nameValuePair "image-${b}" self.nixosConfigurations."hifiberry-${b}".config.system.build.sdImage
            ) boards
          )
        )
      );

      # nix build .#images.rpi5
      images = lib.listToAttrs (
        map (
          b: lib.nameValuePair b self.nixosConfigurations."hifiberry-${b}".config.system.build.sdImage
        ) boards
      );

      nixosConfigurations =
        lib.listToAttrs (map (b: lib.nameValuePair "hifiberry-${b}" (mkHost b)) boards)
        // lib.listToAttrs (map (system: lib.nameValuePair (vmName system) (mkVm system)) systems);

      # nix run .#vm: boot the system in QEMU, web interface on http://localhost:8080
      apps = forAllSystems (system: {
        vm = {
          type = "app";
          program = "${
            self.nixosConfigurations.${vmName system}.config.system.build.vm
          }/bin/run-hifiberry-vm";
          meta.description = "Run HiFiBerryOS in a QEMU virtual machine (web interface on http://localhost:8080)";
        };
      });

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check ${self}/flake.nix $(find ${self}/pkgs ${self}/modules ${self}/hosts -name '*.nix')
            touch $out
          '';
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          toplevel-rpi5 = self.nixosConfigurations.hifiberry-rpi5.config.system.build.toplevel;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
