{
  description = "A Raspberry Pi music player with HiFiBerryOS on NixOS";

  # Prebuilt Raspberry Pi kernel and HiFiBerryOS packages, so building the
  # image downloads them instead of compiling them.
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://sweenu.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "sweenu.cachix.org-1:DvQl16NWBp41k5IlxTODTOrIThyGRj8/ekrXxEheBQ0="
    ];
  };

  inputs.hifiberry-nixos.url = "github:sweenu/hifiberry-nixos";

  outputs =
    { hifiberry-nixos, ... }:
    {
      # Build the SD card image:
      #   nix build .#nixosConfigurations.hifiberry.config.system.build.sdImage
      # Update the running device:
      #   nixos-rebuild switch --flake .#hifiberry --target-host hifiberry@hifiberry.local --sudo --ask-sudo-password
      nixosConfigurations.hifiberry = hifiberry-nixos.lib.nixosSystem {
        board = "rpi4"; # rpi02, rpi3, rpi4 or rpi5
        modules = [ ./configuration.nix ];
      };
    };
}
