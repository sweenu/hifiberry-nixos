# The HiFiBerryOS system as a virtual machine, to try it on a computer before
# flashing an SD card: `nix run .#vm`, then open http://localhost:8080.
#
# Everything runs as on the Pi (PipeWire, AudioControl, the configuration
# server, nginx with the web interface, the auth gateway, the players) except
# what needs the Pi's hardware: there is no HiFiBerry card to detect, no
# Bluetooth adapter and no boot firmware. The VM gets a virtual sound card
# whose output goes nowhere.
{ lib, modulesPath, ... }:
{
  imports = [
    ./common.nix
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  networking.hostName = "hifiberry";

  # Nothing to detect: without a HAT, detection would only log failures.
  systemd.services.config-detect.enable = false;
  hifiberry.bluetooth.enable = false;
  hifiberry.bleProvisioning.enable = false;

  virtualisation = {
    memorySize = 2048;
    cores = 2;
    diskSize = 4096;
    graphics = false;
    forwardPorts = [
      # Web interface: http://localhost:8080
      {
        from = "host";
        host.port = 8080;
        guest.port = 80;
      }
      # SSH: ssh -p 2222 hifiberry@localhost (password hifiberry)
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];
    # A virtual sound card, so ALSA, PipeWire and AudioControl have a device.
    qemu.options = [
      "-audiodev none,id=snd0"
      "-device intel-hda"
      "-device hda-duplex,audiodev=snd0"
    ];
  };

  system.stateVersion = lib.mkDefault "26.05";
}
