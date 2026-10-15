# All HiFiBerryOS components as Nix packages, as a package scope so that they can
# depend on each other and share the pinned `sources`.
{
  pkgs,
  lib ? pkgs.lib,
}:

lib.makeScope pkgs.newScope (self: {
  sources = pkgs.callPackage ./sources.nix { };

  # Core (hbos-minimal)
  audiocontrol = self.callPackage ./audiocontrol { };
  configurator = self.callPackage ./configurator { };
  webui = self.callPackage ./webui { };
  hifiberry-auth = self.callPackage ./hifiberry-auth { };
  hateeprom = self.callPackage ./hateeprom { };
  hifiberry-dsp = self.callPackage ./hifiberry-dsp { };
  dspprofiles = self.callPackage ./dspprofiles { };
  pipewire-api = self.callPackage ./pipewire-api { };
  input-processor = self.callPackage ./input-processor { };
  speakereq = self.callPackage ./speakereq { };
  mpd = self.callPackage ./mpd { inherit (pkgs) mpd; };

  # Full set (hbos-full)
  hifiberry-bluetooth = self.callPackage ./hifiberry-bluetooth { };
  vu-meter = self.callPackage ./vu-meter { };
  roomeq = self.callPackage ./roomeq { };
  raat = self.callPackage ./raat { };

  # Players published as extensions
  sendspin = self.callPackage ./sendspin { };
  librespot = self.callPackage ./librespot { inherit (pkgs) librespot; };
  shairport = self.callPackage ./shairport { };
  squeezelite = self.callPackage ./squeezelite { inherit (pkgs) squeezelite; };
  analog-recognition = self.callPackage ./analog-recognition { };
  aes67 = self.callPackage ./aes67 { };
  usbaudio = self.callPackage ./usbaudio { };
  analoginput = self.callPackage ./analoginput { };

  # Tools
  acr-webmcp = self.callPackage ./acr-webmcp { };
  nowplaying-sdl = self.callPackage ./nowplaying-sdl { };
  songcompare = self.callPackage ./songcompare { };
  hash-password = self.callPackage ./hash-password { };
})
