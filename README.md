# hifiberry-nixos

Turn a Raspberry Pi with a [HiFiBerry](https://www.hifiberry.com) sound card
into a network music player, declared in your NixOS configuration.

This is [HiFiBerryOS](https://github.com/hifiberry/hifiberry-os) on NixOS:
every component of the Debian-based HiFiBerryOS packaged with Nix, and a NixOS
module that wires them together the way HiFiBerryOS does. You get its web
interface, its players and its sound card handling, with your configuration in
a flake, atomic updates and rollbacks.

> [!WARNING]
> **This project is vibe-coded.** It was written largely by an AI coding
> assistant, under review, and has not been audited. It is in daily use as its
> author's Music Assistant speaker (a Raspberry Pi 4 with a DAC+), which is the
> setup that is tested on real hardware; everything else is built and
> evaluated in CI but less exercised. Issues and pull requests are welcome.

## Contents

- [What you get](#what-you-get)
- [Getting started](#getting-started)
- [Building and flashing the SD card image](#building-and-flashing-the-sd-card-image)
- [First boot](#first-boot)
- [Configuration](#configuration)
- [Updating a device](#updating-a-device)
- [Binary cache](#binary-cache)
- [Trying it in a virtual machine](#trying-it-in-a-virtual-machine)
- [Reference](#reference)
- [Development](#development)
- [Licenses](#licenses)

## What you get

- **Boards:** Raspberry Pi Zero 2, 3, 4 and 5 (64-bit), with the Raspberry Pi
  kernel, which carries the HiFiBerry drivers and device tree overlays
  (through [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi)).
- **Every HiFiBerry card** HiFiBerryOS supports, detected on the first boot or
  declared with `hifiberry.soundcard`.
- **Players:** Music Assistant (Sendspin) and Bluetooth audio on by default;
  AirPlay 1 and 2, Spotify Connect, Squeezebox, MPD, Roon Ready and others one
  option away.
- **HiFiBerryOS' web interface** at `http://<name>.local/`, with its setup
  wizard, settings, volume, EQ and system information, and its password
  protection.
- **Appliance conveniences:** Wi-Fi from a `wifi.txt` on the SD card, renaming
  from the web interface, store garbage collection, prebuilt packages.

Everything HiFiBerryOS installs with `install-all` and `apt install
hbos-full` is packaged:

| Component | HiFiBerryOS package | Here |
|---|---|---|
| Raspberry Pi kernel with the HiFiBerry sound card drivers and device tree overlays | Raspberry Pi OS kernel | [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) vendor kernel |
| PipeWire + WirePlumber with HiFiBerry's rate policy, headless and Bluetooth rules | `hifiberry-pipewire-configs` | `modules/pipewire.nix` |
| Speaker EQ and analog input processor (RIAA) filter chains | `ladspa-speakereq`, `hifiberry-input-processor` | `pkgs/speakereq`, `pkgs/input-processor` |
| PipeWire REST API | `pipewire-api` | `pkgs/pipewire-api` |
| AudioControl (player, volume, library, metadata daemons) | `hifiberry-audiocontrol` | `pkgs/audiocontrol` |
| Configuration server and `config-*` tools | `hifiberry-configurator` | `pkgs/configurator` |
| Web interface (Vue), nginx front door | `hifiberry-webui` | `pkgs/webui`, `modules/webui.nix` |
| Authentication gateway | `hifiberry-auth` | `pkgs/hifiberry-auth` |
| HAT EEPROM tools and images | `hifiberry-eeprom` | `pkgs/hateeprom` |
| DSP toolkit and profiles | `hifiberry-dsp`, `hifiberry-dspprofiles` | `pkgs/hifiberry-dsp`, `pkgs/dspprofiles` |
| Bluetooth audio | `hifiberry-bluetooth` | `pkgs/hifiberry-bluetooth` |
| VU meter, RoomEQ | `hifiberry-vu-meter`, `roomeq` | `pkgs/vu-meter`, `pkgs/roomeq` |
| MPD 0.24.13 with HiFiBerry's PipeWire patch | `hifiberry-mpd` | `pkgs/mpd` |
| Roon Ready (RAAT) | `hifiberry-raat` | `pkgs/raat` (binaries from HiFiBerry's repository) |
| Music Assistant (Sendspin), ported to sendspin-cpp 0.9.5 | `hifiberry-sendspin` | `pkgs/sendspin` |
| Spotify Connect (librespot 0.8 + HiFiBerry patches) | `hifiberry-librespot` | `pkgs/librespot` |
| AirPlay 1 and 2 (shairport-sync, nqptp) | `hifiberry-shairport` | `pkgs/shairport` |
| Squeezebox / LMS (squeezelite) | `hifiberry-squeezelite` | `pkgs/squeezelite` |
| Analog input with track recognition, AES67, USB audio gadget, analog pass-through | `hifiberry-analog-recognition`, `hifiberry-aes67`, `hifiberry-usbaudio`, `hifiberry-analoginput` | `pkgs/…`, off by default |
| MCP server, SDL now-playing display | `hifiberry-acr-webmcp`, `nowplaying-sdl` | `modules/webmcp.nix`, `pkgs/nowplaying-sdl` (package only) |

## Getting started

### A new flake, from the template

```sh
mkdir living-room && cd living-room
nix flake init -t github:sweenu/hifiberry-nixos
```

This creates:

- `flake.nix`, which defines the system with `hifiberry-nixos.lib.nixosSystem`.
  Set your board there: `rpi02`, `rpi3`, `rpi4` or `rpi5`.
- `configuration.nix`, which enables HiFiBerryOS and lists the common options,
  commented out.

Then [build the image](#building-and-flashing-the-sd-card-image).

### In an existing flake

Add the input and define the device with `lib.nixosSystem`:

```nix
{
  inputs.hifiberry-nixos.url = "github:sweenu/hifiberry-nixos";

  outputs = { hifiberry-nixos, ... }@inputs: {
    nixosConfigurations.living-room = hifiberry-nixos.lib.nixosSystem {
      board = "rpi4";
      modules = [ ./hosts/living-room.nix ];
      # Optional, passed through to nixosSystem:
      specialArgs = { inherit inputs; };
    };
  };
}
```

```nix
# hosts/living-room.nix
{
  hifiberry.enable = true;
  hifiberry.soundcard = "hifiberry-dacplus-std";
  hifiberry.setup.systemName = "Living room";
  users.users.hifiberry.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA… you@laptop" ];
  system.stateVersion = "26.05";
}
```

`lib.nixosSystem` is
[`nixos-raspberrypi.lib.nixosSystem`](https://github.com/nvmd/nixos-raspberrypi)
with three additions: the board's modules, the HiFiBerryOS module
(`nixosModules.default`) and the SD card layout (`nixosModules.sd-image`).
Every other argument is passed through, so your shared modules and
`specialArgs` work as on your other hosts.

Two things to keep in mind:

- **Do not make `hifiberry-nixos` follow your own `nixpkgs`.** It builds on the
  nixpkgs that nixos-raspberrypi pins, and that is what the binary caches
  hold: the Raspberry Pi kernel and the HiFiBerryOS packages download instead
  of compiling. To use your own nixpkgs anyway, pass `nixpkgs = inputs.nixpkgs;`
  to `lib.nixosSystem`, and expect to build the kernel.
- **To assemble the system yourself**, use the modules directly:
  `nixos-raspberrypi.lib.nixosSystem` with
  `nixos-raspberrypi.nixosModules.raspberry-pi-4.base`,
  `hifiberry-nixos.nixosModules.default` and
  `hifiberry-nixos.nixosModules.sd-image`.

## Building and flashing the SD card image

```sh
nix build .#nixosConfigurations.living-room.config.system.build.sdImage
```

The image is in `result/sd-image/` (`.img.zst`).

**Building on an x86_64 machine** needs a way to run aarch64 builds. Thanks to
the [binary cache](#binary-cache), only small derivations (configuration
files, the image itself) are actually built. Either option works:

- **Emulation**, on NixOS: `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];`
- **A remote aarch64 builder**, for example a Raspberry Pi or a cloud machine.

**Flashing:** [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
("Use custom") takes the `.img.zst` directly; for other tools, decompress it
first with `unzstd`. From a shell:

```sh
zstdcat result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

## First boot

1. **Wi-Fi** (skip this with Ethernet). The card's first partition, `FIRMWARE`,
   is a FAT partition any computer can open. Copy `wifi.txt.example` there to
   `wifi.txt` and fill it in:

   ```
   ssid=MyNetwork
   password=MyPassword
   ```

   On boot the device adds the network to NetworkManager and deletes the file.
   Unmount the card before removing it, or the file may not be written.

2. **Boot.** The first boot expands the root filesystem to the card. Without
   `hifiberry.soundcard`, it also detects the card and reboots once.

3. **Web interface:** `http://hifiberry.local/`, or `http://<hostname>.local/`.
   The setup wizard asks for:
   - a password for system changes,
   - the device name,
   - the sound card,
   - the streaming services.

   You can [declare all of it](#skipping-the-setup-wizard) instead.

4. **SSH:** `ssh hifiberry@<hostname>.local`. The initial password is
   `hifiberry`, for SSH (until you add a key) and `sudo`. Change it with
   `passwd`, or set `users.users.hifiberry.hashedPassword`.

## Configuration

Everything is under `hifiberry.*`; the main options are below, and
[docs/options.md](docs/options.md) lists every one. The module sets its
defaults with `lib.mkDefault` wherever you might reasonably want something
else. Anything it adds to lists (packages, firewall ports, services) merges
with yours.

### Sound card

`hifiberry.soundcard` takes the card's device tree overlay, the same one
HiFiBerryOS' detection picks. Declaring it saves the detection reboot and
keeps the card fixed across rebuilds:

| Card | `hifiberry.soundcard` |
|---|---|
| DAC+ / Amp2, Amp4 | `hifiberry-dacplus-std` |
| DAC+ Pro, DAC2 Pro | `hifiberry-dacplus-pro` |
| DAC2 HD | `hifiberry-dacplushd` |
| DAC+ ADC | `hifiberry-dacplusadc` |
| DAC+ ADC Pro, DAC2 ADC Pro | `hifiberry-dacplusadcpro` |
| DAC+ DSP | `hifiberry-dacplusdsp` |
| DAC8x, DAC8x/ADC8x | `hifiberry-dac8x` |
| DAC+ Light, DAC+ Zero, MiniAmp, Beocreate | `hifiberry-dac` |
| ADC | `hifiberry-adc` |
| Digi+ | `hifiberry-digi` |
| Digi+ Pro, Digi2 Pro | `hifiberry-digi-pro` |
| Amp+ | `hifiberry-amp` |
| Amp3 | `hifiberry-amp3` |
| Amp4 Pro | `hifiberry-amp4pro` |
| Amp100 | `hifiberry-amp100,automute` |

Left `null` (the default), the card is detected as on HiFiBerryOS.

### Players

| Player | Option | Default |
|---|---|---|
| Music Assistant (Sendspin) | `hifiberry.players.sendspin.enable` | on |
| Bluetooth audio | `hifiberry.bluetooth.enable` | on |
| AirPlay 1 and 2 | `hifiberry.players.shairport.enable` | off |
| Spotify Connect | `hifiberry.players.librespot.enable` | off |
| Squeezebox / LMS | `hifiberry.players.squeezelite.enable` | off |
| MPD | `hifiberry.players.mpd.enable` | off |
| Roon Ready (unfree) | `hifiberry.players.raat.enable` | off |
| Analog input with track recognition, AES67, USB audio, analog pass-through | `hifiberry.players.{analogRecognition,aes67,usbaudio,analoginput}.enable` | off |

An enabled player starts on the first boot. After that, the web interface
turns players on and off. `hifiberry.players.<name>.autoStart = false`
installs a player without starting it.

#### Music Assistant (Sendspin)

The Sendspin player is HiFiBerry's `sendspind`, ported to sendspin-cpp 0.9.5
so that it speaks Sendspin 1.0 (encrypted connections, pairing, and the timing
fields current Music Assistant servers expect). HiFiBerry's own build still
uses a pre-1.0 client that Music Assistant treats as legacy, which shows up as
streams that collapse after a pause and volume changes that do nothing.

The first time Music Assistant finds the speaker, the speaker appears there as
a new, unpaired player. Approve it in Music Assistant, or pair it:

- When the server starts a pairing, the 6-digit code is written to the
  player's log: `journalctl --user-unit sendspin -f` (as root).
- The pairing token (`SP:…`) is printed in the same log when the player starts.

The speaker's identity (the `client_id` Music Assistant knows it by) is a key
pair kept in `~hifiberry/.local/state/sendspind/state.json`. It survives
renames and updates; delete the file to make the speaker a new device.

Other components, each on by default:

| Component | Option |
|---|---|
| DSP toolkit (only for DSP boards) | `hifiberry.dsp.enable` |
| Room measurement and correction | `hifiberry.roomeq.enable` |
| VU meter | `hifiberry.vuMeter.enable` |
| Wi-Fi setup over Bluetooth LE | `hifiberry.bleProvisioning.enable` |

### Skipping the setup wizard

Everything the web interface's first-run wizard asks can be declared, and the
wizard is then skipped:

```nix
hifiberry.setup = {
  skipWizard = true;
  systemName = "Living room";             # hostname living-room(.local)
  webAuth = {
    protection = "risky";                 # "off", "risky" (system changes) or "all"
    hashedPassword = "$argon2id$v=19$…";  # nix run github:sweenu/hifiberry-nixos#hash-password
    # hashedPasswordFile = "/run/secrets/…";  # keeps the hash out of the store
  };
};
```

- **Leaving an option `null`** (the default) keeps it with the web interface.
- **A declared `systemName`** fixes the device name: the web interface can no
  longer change it.
- **A declared password and protection** are applied on every boot.

### Networking, SSH and the firewall

- **NetworkManager** manages the network. The configurator's network settings
  and `wifi.txt` go through it.
- **SSH** is on (`hifiberry.openssh.enable`). It accepts passwords only until
  the `hifiberry` user has an authorized key.
- **The firewall stays on.** `hifiberry.openFirewall` opens the web interface
  and the ports of the enabled players; mDNS is opened by Avahi. AirPlay,
  Spotify Connect, Roon and Squeezelite pick ports at runtime, so enabling
  them also opens the ephemeral range 32768-60999. For HiFiBerryOS' behaviour
  (no firewall), set `networking.firewall.enable = false`.
- **The hostname** defaults to `hifiberry` and is renamed from the web
  interface, unless you declare `hifiberry.setup.systemName`.

### Adding your own software

The device is an ordinary NixOS system. Add packages, services, users or
anything else as on any NixOS host:

```nix
{
  environment.systemPackages = [ pkgs.htop ];
  services.tailscale.enable = true;
  time.timeZone = "Europe/Paris";
}
```

To change a default the module sets, assign it:

- **`lib.mkDefault` defaults**, such as `nix.gc.options`,
  `networking.networkmanager.enable` or `documentation.enable`: a plain
  assignment wins.
- **Required settings** are set without `mkDefault`; use `lib.mkForce` if you
  really mean to change one.

The packages are also available on their own: as `packages.<system>.<name>`,
or through `overlays.default` as `pkgs.hifiberry.<name>`.

## Updating a device

From the machine that holds your flake:

```sh
nixos-rebuild switch --flake .#living-room --target-host hifiberry@living-room.local --sudo --ask-sudo-password
```

Or on the device, with the flake in a Git repository it can reach:

```sh
sudo nixos-rebuild switch --flake github:you/your-config#living-room
```

Deploy tools such as [deploy-rs](https://github.com/serokell/deploy-rs) or
[colmena](https://github.com/zhaofengli/colmena) work as for any NixOS host.

## Binary cache

This repository's CI builds every package for aarch64-linux and pushes it to
[sweenu.cachix.org](https://sweenu.cachix.org); nixos-raspberrypi does the
same for the kernel and firmware at
[nixos-raspberrypi.cachix.org](https://nixos-raspberrypi.cachix.org).

- **On the device**, `hifiberry.binaryCache.enable` (on by default) adds the
  cache, so updates download the packages.
- **On the machine building the image**, accept the flake's `nixConfig` when
  Nix asks, or add the caches yourself:

  ```nix
  nix.settings = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" "https://sweenu.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "sweenu.cachix.org-1:DvQl16NWBp41k5IlxTODTOrIThyGRj8/ekrXxEheBQ0="
    ];
  };
  ```

The packages match the cache when the system is built on this flake's
nixpkgs, which is what `lib.nixosSystem` does.

## Trying it in a virtual machine

```sh
nix run github:sweenu/hifiberry-nixos#vm
```

This boots the system in QEMU. It runs everything except what needs the Pi's
hardware: there is no HiFiBerry card, no Bluetooth and no boot firmware.

- **Web interface:** http://localhost:8080
- **SSH:** `ssh -p 2222 hifiberry@localhost`, password `hifiberry`

Its disk is `hifiberry.qcow2` in the current directory; delete it to start
over.

## Reference

- [docs/options.md](docs/options.md): every option, generated from the module.
- [docs/differences.md](docs/differences.md): how this differs from
  HiFiBerryOS, and why.
- [docs/updating.md](docs/updating.md): updating the packaged components.

## Development

The development environment is managed with [devenv](https://devenv.sh):

```sh
devenv shell             # or `direnv allow` with .envrc
build-packages           # build every package for this machine
eval-example rpi4        # evaluate the example configuration for a board
image rpi4               # build the example SD card image
fmt && lint              # nixfmt, statix, deadnix
```

CI (`.github/workflows/build.yml`) runs on GitHub's arm64 runners, for every
push and pull request:

- evaluates every example system and the VMs, and checks formatting;
- checks that `docs/options.md` is up to date:
  `cp $(nix build --print-out-paths --no-link .#options-doc) docs/options.md`;
- builds every package and pushes them to Cachix (with a `CACHIX_AUTH_TOKEN`
  secret);
- builds the example Raspberry Pi 4 system end to end.

The `example-<board>` configurations are the template's `configuration.nix`
on each board.

## Licenses

Everything that is built from source is free software, so this repository can
be public; it only contains Nix expressions, patches and pins that reference
the upstream sources, and the sources it points to are:

- HiFiBerry's own components (AudioControl, configurator, web UI, auth,
  DSP toolkit and profiles, bluetooth, VU meter, RoomEQ, pipewire-api, input
  processor, speaker EQ, sendspin, analog recognition, eeprom tools, the
  wrapper scripts in hifiberry-os): **MIT**. The hifiberry-os repository has no
  top-level LICENSE file, but every package in it declares its license in
  `debian/copyright` (MIT, except the metapackage, the RAAT and squeezelite
  packaging and usagecollector, which are GPL-3+).
- MPD: GPL-2+. squeezelite: GPL-3+. shairport-sync, nqptp: MIT/GPL-2. librespot:
  MIT. sendspin-cpp and its libraries: Apache-2.0 / BSD / Opus BSD. songrec:
  GPL-3. The Raspberry Pi kernel and firmware come from nixos-raspberrypi
  (GPL-2 kernel, Raspberry Pi's redistributable firmware license).
- **RAAT is the exception.** `pkgs/raat` downloads HiFiBerry's published
  `hifiberry-raat` Debian package at build time; the Roon RAAT SDK inside it is
  proprietary and is not redistributed by this repository (nothing of it is
  checked in). It is marked `unfreeRedistributable`, built only when the
  player is enabled, and can be turned off.

This repository itself is MIT licensed (see LICENSE).
