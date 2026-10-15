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
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  hifiberry.enable = true;

  # Nothing to detect: without a HAT, detection would only log failures.
  systemd.services.config-detect.enable = false;
  # Creates the "Softvol" control from an ALSA state written for the HiFiBerry
  # card (sndrpihifiberry), which the VM's virtual card cannot take.
  systemd.services.volume-restore.enable = false;
  # Saves the HiFiBerry card's volume every minute; with no HiFiBerry card it
  # can only fail.
  systemd.services.volume-store.enable = false;
  systemd.timers.volume-store.enable = false;
  # The file the configurator reads and writes in place of config.txt.
  systemd.tmpfiles.rules = [
    "d /boot/firmware 0755 root root -"
    "f /boot/firmware/hifiberry.txt 0644 root root -"
  ];
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
