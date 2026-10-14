# Updating components

Every upstream repository is pinned in `pkgs/sources.nix` with a commit and a
hash; versions are in the package files. HiFiBerryOS itself builds the tip of
each repository's default branch (see `packages/repos.md` in hifiberry-os), so
"the current HiFiBerryOS" is "the current HEAD of each of these".

```sh
devenv shell
prefetch-source hifiberry acr main        # prints rev + hash for pkgs/sources.nix
```

Then set the version in `pkgs/<name>/default.nix` (from `debian/changelog`,
`Cargo.toml`, `setup.py` or `package.json` of the component) and rebuild.

Component-specific notes:

- **webui**: after bumping, refresh `npmDepsHash` with
  `prefetch-npm-deps package-lock.json` in the hbos-ui checkout.
- **Rust packages** (audiocontrol, vu-meter, analog-recognition, songcompare,
  roomeq): copy the source's `Cargo.lock` to `pkgs/<name>/Cargo.lock` after
  bumping, so evaluation does not need the fetched source. pipewire-api ships
  none upstream; run `cargo generate-lockfile` in its checkout instead.
- **sendspin**: `CMakeLists.txt` and `cmake/host.cmake` of sendspin-cpp pin
  the FetchContent dependencies (sendspin-cpp commit, ArduinoJson, micro-flac,
  micro-opus, IXWebSocket); update those entries in `pkgs/sources.nix` together.
- **shairport, squeezelite, mpd, librespot**: the upstream commits/tags are
  the ones hifiberry-shairport, hifiberry-squeezelite, hifiberry-os
  (`packages/mpd/src/debian/rules`) and hifiberry-librespot build.
- **raat**: the version and SHA-256 come from the `Packages` index of
  `http://debianrepo.hifiberry.com/dists/trixie/main/binary-arm64/`.
- **nixos-raspberrypi / nixpkgs**: `nix flake update`.
