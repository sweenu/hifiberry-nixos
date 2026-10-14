# Raspberry Pi boot firmware configuration for HiFiBerry sound cards.
#
# HiFiBerryOS disables the onboard and HDMI audio, enables I2C and SPI
# (`config-configtxt --default-config`) and writes the detected card's
# `dtoverlay=` line into config.txt at boot. On NixOS config.txt is generated
# from the configuration, so those runtime lines go to a separate file,
# /boot/firmware/hifiberry.txt, which config.txt includes.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hifiberry;
in
{
  config = lib.mkIf cfg.enable {
    hardware.raspberry-pi.config.all = {
      base-dt-params = {
        audio = {
          enable = true;
          value = lib.mkForce "off";
        };
        i2c_arm = {
          enable = true;
          value = "on";
        };
        spi = {
          enable = true;
          value = "on";
        };
      };
      dt-overlays.vc4-kms-v3d = {
        enable = true;
        params.noaudio.enable = true;
      };
    };

    hardware.raspberry-pi.extra-config = lib.mkAfter (
      ''
        [all]
      ''
      + lib.optionalString (cfg.soundcard != null) ''
        dtoverlay=${cfg.soundcard}
      ''
      + ''
        # HiFiBerryOS runtime sound card configuration (config-detect, config-configtxt)
        include hifiberry.txt
      ''
    );

    # Make sure the included file exists so the firmware has nothing to complain
    # about on the first boot.
    systemd.services.hifiberry-firmware-config = {
      description = "Create /boot/firmware/hifiberry.txt";
      wantedBy = [ "multi-user.target" ];
      before = [ "config-detect.service" ];
      unitConfig.RequiresMountsFor = "/boot/firmware";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -e /boot/firmware/hifiberry.txt ]; then
          printf '# HiFiBerry sound card configuration, managed by config-detect/config-configtxt\n' > /boot/firmware/hifiberry.txt
        fi
      '';
    };

    environment.systemPackages = [ pkgs.raspberrypi-eeprom ];
  };
}
