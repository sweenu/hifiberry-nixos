# Notes for coding agents

HiFiBerryOS (HiFiBerry's Raspberry Pi OS based audio distribution) rebuilt as
a NixOS module and flake. Most of the code was written by agents; this file is
what the next one needs to know that the README does not say. Read
[README.md](README.md) for what the project does,
[docs/differences.md](docs/differences.md) for where it departs from
HiFiBerryOS, and [docs/updating.md](docs/updating.md) for bumping components.

## Layout

- `flake.nix`: `lib.nixosSystem` (board modules + `nixosModules.default` +
  SD image), packages, `example-<board>` and `vm-*` configurations, apps,
  checks, the options doc generator.
- `modules/`: the NixOS module, one file per component. Options live in
  `modules/options.nix`, except the players (`players/default.nix`) and
  self-contained features such as `kiosk.nix`, which declare their own.
  Shared helpers are in `modules/lib.nix`.
- `pkgs/`: one directory per HiFiBerryOS package; every upstream source is
  pinned in `pkgs/sources.nix`.
- `examples/vm.nix`, `templates/default/`: the VM and the downstream starting
  point. Keep the template generic: nothing personal (keys, names, hosts).

## Source of truth

What a component should do is what HiFiBerryOS does: the `hifiberry/hifiberry-os`
meta repository (`packages/*/build.sh`, `packages/repos.md`, docs) and each
component's `debian/` directory (units, postinst, conffiles). Reproduce that
behaviour; when NixOS forces a different mechanism, or a deliberate change
is made, record it in `docs/differences.md`.

## Module conventions

- Everything is under `hifiberry.*` and gated on `hifiberry.enable`.
- Defaults a downstream user might reasonably change are set with
  `lib.mkDefault` (or are options), so a plain assignment overrides them.
  Reserve `mkForce` for things that would break the system otherwise.
- New features beyond HiFiBerryOS' default install are off by default.
- Option descriptions are user documentation: say what it does, the default
  behaviour and why someone would change it.

## Generated files and checks

- `docs/options.md` is generated. After any option change:
  `cp $(nix build --print-out-paths --no-link .#options-doc) docs/options.md`
  (the `options-doc` check fails CI otherwise).
- Formatting is nixfmt. The flake formatter is bare nixfmt, so pass files:
  `nix fmt -- <files>`; plain `nix fmt` waits on stdin. In devenv, `fmt`
  formats everything and `lint` runs statix and deadnix.
- Before pushing:
  `nix flake check --no-build` and
  `nix build --no-link .#checks.x86_64-linux.formatting .#checks.x86_64-linux.options-doc`.
  `eval-example rpi4` (devenv) evaluates the Pi configuration.

## CI and the binary cache

`.github/workflows/build.yml` runs on arm64 runners: evaluation and
formatting, every package (pushed to the `sweenu` Cachix cache), and the
`example-rpi4` system build (`checks.aarch64-linux.example-rpi4`). No images
are published; users build their own (README). A green run means the Pi
system builds, not that it works on hardware.

## Testing

- `nix run .#vm` boots the x86_64 VM: web interface on localhost:8080, SSH on
  2222 (`hifiberry`/`hifiberry`). No HiFiBerry card, Bluetooth or firmware,
  and without KVM it is slow; give services minutes, not seconds.
- To test an option, extend the VM configuration from a scratch flake
  (`nixosConfigurations.vm-x86_64.extendModules { modules = [ … ]; }`)
  instead of editing `examples/vm.nix`.
- Building aarch64 locally needs binfmt (qemu-aarch64); it is slow, CI does it
  natively.

## Component notes

- **Sendspin**: `pkgs/sendspin/sendspin-cpp-0.9.patch` ports HiFiBerry's
  `sendspind` wrapper (pinned at its own commit) to sendspin-cpp 0.9.x, the
  Sendspin 1.0 protocol Music Assistant requires; HiFiBerry's build is a
  legacy pre-1.0 client. Bumping sendspin-cpp means regenerating the patch
  against the new API. Check protocol compliance against aiosendspin's server
  with `allow_unencrypted=False, allow_noncompliant_clients=False`.
- **Kiosk** (`modules/kiosk.nix`): Chromium in cage, since nixpkgs has no WPE
  WebKit (HiFiBerryOS uses cog). The comments there explain each flag; most
  of them fix a failure seen in testing, so don't drop one without retesting.
- **raat** is unfree binaries from HiFiBerry's Debian repository.

## Commits

Pushing straight to `main` is fine for this repository. Say in the commit
message why the change is made and how it was verified (VM, aarch64 build,
compliance test), and what was not.
