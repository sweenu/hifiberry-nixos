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
    # dtparam=i2c_arm=on is already in config.txt; card detection checks this file
    # and would otherwise try to add it, which fails when it runs as the player user.
    populateFirmwareCommands = lib.mkAfter ''
      printf '# HiFiBerry sound card configuration, managed by config-detect/config-configtxt\ndtparam=i2c_arm=on\n' > ./firmware/hifiberry.txt
      cat > ./firmware/wifi.txt.example <<'EOF'
      # To join a Wi-Fi network on the next boot, copy this file to wifi.txt
      # (in this same folder) and fill in your network. The Pi adds it, then
      # deletes wifi.txt. Leave password= empty for an open network.
      ssid=MyNetwork
      password=MyPassword
      EOF
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
