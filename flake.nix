{
  description = "HiFiBerryOS on NixOS: its components as Nix packages and a NixOS module that turns a Raspberry Pi with a HiFiBerry card into a network music player";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      # Everything CI builds for this repository
      "https://sweenu.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "sweenu.cachix.org-1:DvQl16NWBp41k5IlxTODTOrIThyGRj8/ekrXxEheBQ0="
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

      # The nixos-raspberrypi modules for each supported board.
      boardModules = with nixos-raspberrypi.nixosModules; {
        rpi02 = [
          raspberry-pi-02.base
          raspberry-pi-02.bluetooth
        ];
        rpi3 = [ raspberry-pi-3.base ];
        rpi4 = [
          raspberry-pi-4.base
          raspberry-pi-4.bluetooth
        ];
        rpi5 = [
          raspberry-pi-5.base
          raspberry-pi-5.bluetooth
        ];
      };

      # The template's configuration on each board: what CI builds, and what
      # a new user starts from.
      mkExample =
        board:
        self.lib.nixosSystem {
          inherit board;
          modules = [ ./templates/default/configuration.nix ];
        };

      # The system as a QEMU virtual machine, for trying it on a computer.
      mkVm =
        system:
        nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.default
            ./examples/vm.nix
            { nixpkgs.hostPlatform = system; }
          ];
        };
      vmName = system: "vm-${lib.head (lib.splitString "-" system)}";

      # docs/options.md: every `hifiberry.*` option, from the module itself.
      optionsDoc =
        system:
        let
          pkgs = pkgsFor system;
          eval = nixpkgs.lib.nixosSystem {
            modules = [
              self.nixosModules.default
              { nixpkgs.hostPlatform = system; }
            ];
          };
          repoUrl = "https://github.com/sweenu/hifiberry-nixos/blob/main";
          doc = pkgs.nixosOptionsDoc {
            options = builtins.removeAttrs eval.options.hifiberry [
              "internal"
              "_module"
            ];
            transformOptions =
              opt:
              opt
              // {
                declarations = map (
                  decl:
                  let
                    path = lib.removePrefix "${self}/" (toString decl);
                  in
                  {
                    name = path;
                    url = "${repoUrl}/${path}";
                  }
                ) opt.declarations;
              };
          };
        in
        pkgs.runCommand "hifiberry-nixos-options.md" { } ''
          {
            echo "# Options"
            echo
            echo "Every option of the HiFiBerryOS module. Generated from the module by"
            echo "\`nix build .#options-doc\`; do not edit by hand."
            echo
            cat ${doc.optionsCommonMark}
          } > $out
        '';
    in
    {
      lib = {
        boards = lib.attrNames boardModules;

        # A NixOS system for a Raspberry Pi with HiFiBerryOS:
        #
        #   hifiberry-nixos.lib.nixosSystem {
        #     board = "rpi4";            # rpi02, rpi3, rpi4 or rpi5
        #     modules = [ ./configuration.nix ];
        #   }
        #
        # It is nixos-raspberrypi.lib.nixosSystem (the Raspberry Pi kernel with
        # the HiFiBerry drivers, firmware, config.txt and bootloader) with the
        # board's modules, the HiFiBerryOS module and the SD card layout added.
        # Every other argument (specialArgs, nixpkgs, ...) is passed through.
        nixosSystem =
          {
            board,
            modules ? [ ],
            ...
          }@args:
          if !(boardModules ? ${board}) then
            throw "hifiberry-nixos.lib.nixosSystem: unknown board \"${board}\", expected one of ${lib.concatStringsSep ", " (lib.attrNames boardModules)}"
          else
            nixos-raspberrypi.lib.nixosSystem (
              builtins.removeAttrs args [ "board" ]
              // {
                modules =
                  boardModules.${board}
                  ++ [
                    self.nixosModules.default
                    self.nixosModules.sd-image
                  ]
                  ++ modules;
              }
            );
      };

      nixosModules = {
        # The HiFiBerryOS module: every option is under `hifiberry.*`, and
        # nothing happens until `hifiberry.enable = true`. On a Raspberry Pi it
        # expects nixos-raspberrypi (lib.nixosSystem provides it); elsewhere,
        # as in the VM, the parts that need the Pi's firmware are left out.
        hifiberry = import ./modules;
        default = self.nixosModules.hifiberry;
        # The SD card layout (firmware and root partitions) and image builder.
        sd-image = import ./modules/sd-image.nix;
      };

      templates.default = {
        path = ./templates/default;
        description = "A Raspberry Pi music player with HiFiBerryOS";
        welcomeText = ''
          Edit configuration.nix (and the board in flake.nix), then build the
          SD card image:

            nix build .#nixosConfigurations.hifiberry.config.system.build.sdImage

          See https://github.com/sweenu/hifiberry-nixos for the rest.
        '';
      };

      overlays.default = final: _prev: {
        hifiberry = mkPackages final;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          hb = mkPackages pkgs;
        in
        lib.filterAttrs (_: v: lib.isDerivation v && lib.meta.availableOn pkgs.stdenv.hostPlatform v) (
          builtins.removeAttrs hb [ "sources" ]
        )
        // {
          options-doc = optionsDoc system;
        }
      );

      nixosConfigurations =
        lib.mapAttrs' (board: _: lib.nameValuePair "example-${board}" (mkExample board)) boardModules
        // lib.listToAttrs (map (system: lib.nameValuePair (vmName system) (mkVm system)) systems);

      apps = forAllSystems (system: {
        # nix run .#vm: boot the system in QEMU, web interface on http://localhost:8080
        vm = {
          type = "app";
          program = "${
            self.nixosConfigurations.${vmName system}.config.system.build.vm
          }/bin/run-hifiberry-vm";
          meta.description = "Run HiFiBerryOS in a QEMU virtual machine (web interface on http://localhost:8080)";
        };
        # nix run .#hash-password: for hifiberry.setup.webAuth.hashedPassword
        hash-password = {
          type = "app";
          program = "${self.packages.${system}.hash-password}/bin/hash-password";
          meta.description = "Hash a web interface password for hifiberry.setup.webAuth.hashedPassword";
        };
      });

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check $(find ${self} -name '*.nix')
            touch $out
          '';
          # docs/options.md matches the module's options.
          options-doc = pkgs.runCommand "check-options-doc" { } ''
            diff -u ${self}/docs/options.md ${optionsDoc system} \
              || { echo "docs/options.md is out of date: cp $(nix build --print-out-paths --no-link .#options-doc) docs/options.md"; exit 1; }
            touch $out
          '';
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          example-rpi4 = self.nixosConfigurations.example-rpi4.config.system.build.toplevel;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
