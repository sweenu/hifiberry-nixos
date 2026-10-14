# An SD card image of a complete HiFiBerryOS system, based on nixos-raspberrypi's
# sd-image. Build with `nix build .#images.rpi5` (or rpi4, rpi3, rpi02) and
# write the result to a card with dd or Raspberry Pi Imager.
{
  config,
  lib,
  nixos-raspberrypi,
  ...
}:
{
  imports = [ nixos-raspberrypi.nixosModules.sd-image ];

  image.baseName =
    let
      cfg = config.boot.loader.raspberry-pi;
    in
    lib.mkForce "hifiberry-nixos-rpi${cfg.variant}-${config.system.nixos.label}";

  sdImage = {
    compressImage = true;
    # Start with a root filesystem that gets expanded to the card on first boot.
    expandOnBoot = true;
    populateFirmwareCommands = lib.mkAfter ''
      printf '# HiFiBerry sound card configuration, managed by config-detect/config-configtxt\n' > ./firmware/hifiberry.txt
    '';
  };

  # A music player has no use for ZFS; leaving it out keeps the image small.
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.zfs.forceImportRoot = false;

  # The image is mutable and meant to be used as the installed system.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = lib.mkDefault "26.05";
}
