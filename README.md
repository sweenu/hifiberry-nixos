# hifiberry-nixos

[HiFiBerryOS](https://github.com/hifiberry/hifiberry-os) on NixOS: every
component of the Debian-based HiFiBerryOS packaged with Nix, NixOS modules that
wire them together the way HiFiBerryOS does, and ready-to-flash SD card images
for the Raspberry Pi Zero 2, 3, 4 and 5 (64-bit).

The result is the system HiFiBerryOS gives you after `install-all` and
`apt install hbos-full`, with the Music Assistant (Sendspin) player and
Bluetooth audio enabled by default and the other players (MPD, Spotify
Connect, AirPlay, Squeezebox, Roon, …) packaged and available as options:

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
| Music Assistant (Sendspin) | `hifiberry-sendspin` | `pkgs/sendspin` |
| Spotify Connect (librespot 0.8 + HiFiBerry patches) | `hifiberry-librespot` | `pkgs/librespot` |
| AirPlay 1 and 2 (shairport-sync, nqptp) | `hifiberry-shairport` | `pkgs/shairport` |
| Squeezebox / LMS (squeezelite) | `hifiberry-squeezelite` | `pkgs/squeezelite` |
| Analog input with track recognition, AES67, USB audio gadget, analog pass-through | `hifiberry-analog-recognition`, `hifiberry-aes67`, `hifiberry-usbaudio`, `hifiberry-analoginput` | `pkgs/…`, off by default |
| MCP server, SDL now-playing display | `hifiberry-acr-webmcp`, `nowplaying-sdl` | `modules/webmcp.nix`, `pkgs/nowplaying-sdl` (package only) |

## Building an SD card image

You need Nix with flakes on an `aarch64-linux` machine, or an x86_64 machine
with `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` (slow) or a remote
aarch64 builder. The flake's `nixConfig` adds the nixos-raspberrypi binary cache
so the kernel and firmware need not be rebuilt; pass `--accept-flake-config`.

```sh
nix build --accept-flake-config .#images.rpi5     # or rpi4, rpi3, rpi02
ls result/sd-image/
```

Write the `.img.zst` to a card (`zstdcat result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync`,
or Raspberry Pi Imager), put it in the Pi with a HiFiBerry HAT, connect
Ethernet and power it on.

On the first boot the card is detected over its HAT EEPROM or I2C, the matching
device tree overlay is written to `/boot/firmware/hifiberry.txt` and the system
reboots once, exactly as HiFiBerryOS does. Then open `http://hifiberry.local/`
(or the device's IP address) for the setup wizard.

The default login is user `hifiberry`, password `hifiberry`, with sudo and
SSH enabled. Change it (`passwd`) or set `hifiberry.initialPassword` and your
SSH keys in your own configuration.

### Trying it in a virtual machine first

On a Linux computer with Nix (flakes enabled), the same system runs in QEMU:

```sh
nix run --accept-flake-config github:sweenu/hifiberry-nixos#vm
```

Then open http://localhost:8080 for the web interface, or
`ssh -p 2222 hifiberry@localhost` (password `hifiberry`). Stop it with
`Ctrl-a x`, or `sudo poweroff` inside it. The VM keeps its state in
`hifiberry.qcow2` in the current directory; delete that file to start over.

Everything runs as on the Pi: PipeWire, AudioControl, the configuration server,
nginx with the web interface and the auth gateway, and the players. What needs
the Pi's hardware is absent: there is no HiFiBerry card (the VM has a virtual
sound card whose output goes nowhere, and the players that require a detected
HiFiBerry card do not start), no Bluetooth and no boot firmware. It is a way to
explore the interface and the services, not to listen to music.

The VM matches your computer's architecture (`x86_64-linux` or
`aarch64-linux`) and uses KVM when available. On macOS it needs a Linux
builder, such as the one nix-darwin provides.

### Prebuilt images

Every push to `main` that builds completely publishes ready-to-flash images
on the [`latest` release](https://github.com/sweenu/hifiberry-nixos/releases/tag/latest):

- https://github.com/sweenu/hifiberry-nixos/releases/download/latest/hifiberry-nixos-rpi4.img.xz

Only the Raspberry Pi 4 image is built by default. For another board, run the
workflow manually (Actions, Build, Run workflow) with its name (rpi02, rpi3,
rpi5) and download the image from the run's artifacts.

Flash one with Raspberry Pi Imager ("Use custom") or balenaEtcher, which take
the `.img.xz` as is, or with
`xzcat hifiberry-nixos-rpi4.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync`.
A Raspberry Pi boots from a raw disk image, not an ISO; this is that image.

The images are built natively on GitHub's free arm64 runners by
`.github/workflows/build.yml`. A manual run (`workflow_dispatch`) takes a list
of boards (rpi02, rpi3, rpi4, rpi5) and keeps the images as workflow
artifacts; a `v*` tag publishes them on a versioned release.

### CI cache

Everything this repository compiles is cached in GitHub's own Actions cache,
with no setup. The packages job keeps its outputs and their runtime closure as
a local Nix binary cache (about 1 GB compressed, well inside the 10 GB the
repository gets) and saves it under a key derived from `flake.lock` and
`pkgs/`. Later runs, and the image jobs, restore it and substitute from it, so
only the packages whose definition changed are rebuilt. Snapshots unused for a
week are evicted by GitHub.

Optionally, the same jobs also push to a [Cachix](https://www.cachix.org)
cache. That is only useful outside CI: with it, the Pi and your own machines
can download the prebuilt packages when you update the system. To enable it,
create a free public cache (by default named `hifiberry-nixos`, or set the
repository variable `CACHIX_CACHE`), save an auth token as the repository
secret `CACHIX_AUTH_TOKEN`, and add the cache to `nixConfig` in `flake.nix`.

## Using the module in your own NixOS configuration

```nix
{
  inputs.hifiberry-nixos.url = "github:sweenu/hifiberry-nixos";

  outputs = { hifiberry-nixos, ... }:
    let nixos-raspberrypi = hifiberry-nixos.inputs.nixos-raspberrypi;
    in {
      nixosConfigurations.livingroom = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = { inherit nixos-raspberrypi; };
        modules = [
          nixos-raspberrypi.nixosModules.raspberry-pi-5.base
          nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
          hifiberry-nixos.nixosModules.default
          hifiberry-nixos.nixosModules.sd-image   # only for building an image
          {
            hifiberry.enable = true;
            hifiberry.soundcard = "hifiberry-dacplus";       # skip the detection reboot
            hifiberry.audiocontrol.secretsFile = ./secrets.txt;  # optional, see below
            hifiberry.players.mpd.enable = true;             # Sendspin + Bluetooth are on by default
            networking.hostName = "livingroom";
            users.users.hifiberry.openssh.authorizedKeys.keys = [ "ssh-ed25519 …" ];
            system.stateVersion = "26.05";
          }
        ];
      };
    };
}
```

The main options (`nix eval` or the files in `modules/` for the full list):

| Option | Default | Meaning |
|---|---|---|
| `hifiberry.enable` | `false` | Turn the whole system on. |
| `hifiberry.user` / `uid` | `hifiberry` / 1000 | The user whose systemd session runs PipeWire and the players (`/etc/hifiberry.user`). |
| `hifiberry.soundcard` | `null` | Device tree overlay of the HAT, e.g. `hifiberry-dacplus`. `null` detects at boot. |
| `hifiberry.audiocontrol.secretsFile` | `null` | `secrets.txt` with HiFiBerry's API credentials (Last.fm, TheAudioDB, Spotify proxy). |
| `hifiberry.players.sendspin.enable` | `true` | Music Assistant (Sendspin). `.autoStart` enables the service on the first boot; the web UI can toggle it afterwards. |
| `hifiberry.players.{mpd,librespot,shairport,squeezelite,raat,analogRecognition,aes67,usbaudio,analoginput}.enable` | `false` | The other players, each packaged and ready to enable. |
| `hifiberry.{bluetooth,dsp,roomeq,vuMeter,bleProvisioning,openssh}.enable` | `true` | Optional services. |
| `hifiberry.webmcp.enable` | `false` | MCP server for AudioControl. |

All packages are also available as `packages.<system>.<name>` and through
`overlays.default` as `pkgs.hifiberry.<name>`.

## How it differs from HiFiBerryOS

HiFiBerryOS is Raspberry Pi OS plus Debian packages; some of its mechanisms do
not translate one to one to a declarative NixOS system. See
[docs/differences.md](docs/differences.md) for the details. In short:

- **Extensions.** HiFiBerryOS installs extra players from its apt repository
  through the web interface. Here players are NixOS options
  (`hifiberry.players.*`); the extensions page shows what is installed but
  cannot install anything.
- **config.txt.** Generated from the configuration on every rebuild. The lines
  HiFiBerryOS writes at runtime (the detected card's overlay) live in
  `/boot/firmware/hifiberry.txt`, which `config.txt` includes, so they survive
  rebuilds. Set `hifiberry.soundcard` to make the overlay declarative instead.
- **Enabling and disabling players** from the web interface works, but through
  the player user's own systemd configuration (`~/.config/systemd/user`)
  rather than `systemctl --global`, because `/etc/systemd/user` is read-only.
- **AudioControl's credentials.** HiFiBerry compiles API keys for Last.fm,
  TheAudioDB and its Spotify OAuth proxy into the binary from a private
  `secrets.txt`. Those are not public; without them scrobbling, TheAudioDB
  lookups and the Spotify account link do not work. Provide your own keys via
  `hifiberry.audiocontrol.secretsFile` if you have them.
- **Roon (RAAT).** The RAAT SDK is proprietary and HiFiBerry's `raat`
  repository is private, so `pkgs/raat` repackages the binaries from
  HiFiBerry's Debian repository (aarch64 only, `allowUnfreePredicate` is set
  for it). It is off unless `hifiberry.players.raat.enable = true`.
- **Hostname.** The static hostname is set in the configuration
  (`networking.hostName`); the web interface can still set the pretty name.
- **No firewall**, like Raspberry Pi OS. Set `networking.firewall.enable = true`
  and open ports yourself if you want one.

## Development

The development environment is managed with [devenv](https://devenv.sh):

```sh
devenv shell          # or `direnv allow` with .envrc
image rpi5            # build an SD image
build-packages        # build every package for this machine
eval-host rpi4        # evaluate a configuration without building
fmt && lint           # nixfmt, statix, deadnix
```

Every upstream component is pinned in `pkgs/sources.nix`. To update one, bump
its `rev` and `hash` (`prefetch-source hifiberry acr main` prints them) and the
version in its `pkgs/<name>/default.nix`. `pkgs/pipewire-api/Cargo.lock` is
kept here because upstream ships none; regenerate it with
`cargo generate-lockfile` when updating that package.

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
