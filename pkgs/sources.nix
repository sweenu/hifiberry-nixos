# Pinned upstream sources for every component HiFiBerryOS is built from.
#
# HiFiBerryOS's own build scripts (packages/*/build.sh in hifiberry/hifiberry-os)
# clone each of these repositories at the tip of its default branch. Here they
# are pinned to a specific commit so the build is reproducible; bump a rev and
# its hash to update a component. `hifiberry-os` is the meta repository itself,
# which carries the in-tree packages (mpd, squeezelite, eeprom, raat,
# pipewire-configs, aes67, usbaudio, analoginput, acr-webmcp).
{ fetchFromGitHub, fetchgit }:
{
  hifiberry-os = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hifiberry-os";
    rev = "5143c24fa6281de86a7628c477095850155e1092";
    hash = "sha256-U0AuZxQrjz+OpGXYLR9g1/upCzspgz6Zn/XRcvxsdpw=";
  };

  # AudioControl (acr): hifiberry-audiocontrol 0.23.6
  acr = fetchFromGitHub {
    owner = "hifiberry";
    repo = "acr";
    rev = "e8c45dfb8a9609610c0cd2a9bc35412dcd24c404";
    hash = "sha256-lU7KWJCEG57ubT6tPEMOk/IEdnjp1RHpOAleKmRY0AE=";
  };

  # hifiberry-configurator 2.18.0
  configurator = fetchFromGitHub {
    owner = "hifiberry";
    repo = "configurator";
    rev = "43feb3f23db4afa3d0363f1fca7b43cda827e368";
    hash = "sha256-sj88Pwo+8ekzlSORQj3dcbFL88zqYepN8BFl2HCvk8U=";
  };

  # hifiberry-webui 0.27.1 (hbos-ui, branch `dev` as used by hifiberry-os)
  hbos-ui = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hbos-ui";
    rev = "782fa58bce04252ceac1bf567d97626e77a3f1b8";
    hash = "sha256-HW8/ER78F4ekNnxMzip4Umra7B/8Q1bs0tklUOpQW28=";
  };

  # hifiberry-dsp 1.5.5 (dsptoolkit, sigmatcpserver)
  hifiberry-dsp = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hifiberry-dsp";
    rev = "551c1950de40ceaa24c8c2e803ed1b8f10dbcf54";
    hash = "sha256-lR/dxQZWNqCeHZdkpb68uyJuHYUXjFkcqO2RpYWQ5vU=";
  };

  # hifiberry-dspprofiles 1.1.1
  dspprofiles = fetchFromGitHub {
    owner = "hifiberry";
    repo = "dspprofiles";
    rev = "34cab4aa104acdd41b851410748e1fd6d0cf2c58";
    hash = "sha256-I5nJccxGEKql9mkYp8eL/MvJHdPl1l0H96ebkExfAYI=";
  };

  # hifiberry-bluetooth 1.0.8
  hbos-bluetooth = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hbos-bluetooth";
    rev = "a2a1ed0372f1cabb52bc5bf747d07f6483260ccb";
    hash = "sha256-4M+WvTEmunKFHpZGIpQcwK2EzaiEwWv0jRd0u3V/Crc=";
  };

  # hifiberry-auth 0.2.2
  hifiberry-auth = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hifiberry-auth";
    rev = "20b5aeef2674eda11b0b0b8e8310db605eb2a3a2";
    hash = "sha256-q5Wdy7CQ4IPoDUFJV5IGLwyMtlp8gl1U2DNmhNViSBs=";
  };

  # pipewire-api 2.2.0
  pipewire-api = fetchFromGitHub {
    owner = "hifiberry";
    repo = "pipewire-api";
    rev = "2dd638b676a7c7e7facad7f4d9d25ff6f67b726c";
    hash = "sha256-wetRoZnssadRu7C2+V0Hg8QvwKNb8YCH06Ns1pPuwNQ=";
  };

  # hifiberry-vu-meter 0.1.4
  vu-meter = fetchFromGitHub {
    owner = "hifiberry";
    repo = "vu-meter";
    rev = "184537ccf0c002ba06b6de39b4faa3288ec1775e";
    hash = "sha256-sBYRMe/vr6zSAFdEUhGUbAPRyRYZBwOkXq7MA3bxPpM=";
  };

  # roomeq 0.7.x
  roomeq = fetchFromGitHub {
    owner = "hifiberry";
    repo = "roomeq";
    rev = "3c112a597052b7340b43d1720353a460f9f15e9c";
    hash = "sha256-lHxy/F05whwKamDc8ovE1G/Ih02+Bj+UFtY6DNDhEG0=";
  };

  # hifiberry-input-processor 1.3.1 (RIAA LADSPA plugin)
  input-processor = fetchFromGitHub {
    owner = "hifiberry";
    repo = "input-processor";
    rev = "333ff7160f38f688e8c9822601850a1d6f4986ed";
    hash = "sha256-qimh0BHb93ISsGdPtt4ZIRpVszoEjHtE5DI9uRX5TLs=";
  };

  # ladspa-speakereq 1.2
  speakereq = fetchFromGitHub {
    owner = "hifiberry";
    repo = "speakereq";
    rev = "f10c669c7107ef16236a3952fb2e915eff2dbac8";
    hash = "sha256-hr4Os764t256Pz/tEkE9hnCNGpS/PdmGt4IGOrow930=";
  };

  # hifiberry-sendspin 0.1.x (Music Assistant player)
  sendspin = fetchFromGitHub {
    owner = "hifiberry";
    repo = "sendspin";
    rev = "235f5e50a02d18f4322500e2845b5cca23dd2591";
    hash = "sha256-sGIphcKFSfeq6L5NfvlE9tddLa95myWykjcNsdrr8Ek=";
  };

  # sendspin-cpp and the libraries its CMake build fetches with FetchContent.
  # sendspin-cpp, newer than the commit hifiberry-sendspin pins: 0.9 speaks the
  # Sendspin 1.0 protocol (pkgs/sendspin/sendspin-cpp-0.9.patch ports the player).
  sendspin-cpp = fetchFromGitHub {
    owner = "Sendspin";
    repo = "sendspin-cpp";
    rev = "b95cf854a784ed308b1f8fe9697f414b02768ddd"; # v0.9.5
    hash = "sha256-swiv8+AfLQelAlfRF5oSCiJ62ZyJjKpaHo8S+YP2lR0=";
  };
  arduinojson = fetchFromGitHub {
    owner = "bblanchon";
    repo = "ArduinoJson";
    rev = "v7.4.1";
    hash = "sha256-CvwL3FDsbQGLkZFC3Z/RWeiT9tO+7ZRpT65YUdRT5dQ=";
  };
  micro-flac = fetchgit {
    name = "micro-flac";
    url = "https://github.com/esphome-libs/micro-flac.git";
    rev = "f9c27d4d0166021db977d7fc37d205b21d81e9f2"; # v0.3.0
    fetchSubmodules = true;
    hash = "sha256-XnwYlGoYk3ra7hg/ni7Sy5EtSKzil6386OGoXY7j5MI=";
  };
  micro-opus = fetchgit {
    name = "micro-opus";
    url = "https://github.com/esphome-libs/micro-opus.git";
    rev = "3e9ce44c56ab8007261d68c511f0162599542aa2"; # v0.3.5
    fetchSubmodules = true;
    hash = "sha256-OV5J8UgL81Rerotu2zjpR5LQfqnYb0e+KkFutP1INqo=";
  };
  ixwebsocket = fetchFromGitHub {
    owner = "machinezone";
    repo = "IXWebSocket";
    rev = "v12.0.1";
    hash = "sha256-2QWIpLVIs2vGuMEhewDyihYdDQBz7SsOtfZ6pE67j2Q=";
  };
  noise-c = fetchFromGitHub {
    owner = "esphome-libs";
    repo = "noise-c";
    rev = "v0.1.13";
    hash = "sha256-5bu3Vh+8w4cVuU9n7oc20uhswJgxVtIeHoIzTjAr/Xo=";
  };

  # hifiberry-analog-recognition 0.4.2
  analog-recognition = fetchFromGitHub {
    owner = "hifiberry";
    repo = "analog-recognition";
    rev = "4204f6efd6c597fea3927e6f69f7e9a8827d75e7";
    hash = "sha256-oefarOrqwTSTLAUgZbAB0ybf9aRc9SPuFE4m4e3NlOA=";
  };

  # hifiberry-librespot 0.8.0.x: packaging, wrapper scripts and patches for librespot
  hifiberry-librespot = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hifiberry-librespot";
    rev = "f01d212da13e51510f24509a8e2141128649870e";
    hash = "sha256-fnebuAUG7+LPRpVf47Pts9X6UtrJnIQv5wZRN9Rowyg=";
  };

  # hifiberry-shairport 5.5.0.x: packaging and wrapper scripts for shairport-sync
  hifiberry-shairport = fetchFromGitHub {
    owner = "hifiberry";
    repo = "hifiberry-shairport";
    rev = "b8643d57a731bd0f96e64f509882ec5cb17fb0d9";
    hash = "sha256-6SxnxHPXSHt8s574v/aZ2ODF5JUKV4sECxCLgqwYw/I=";
  };
  # shairport-sync at the commit hifiberry-shairport builds (5.5 development)
  shairport-sync = fetchFromGitHub {
    owner = "mikebrady";
    repo = "shairport-sync";
    rev = "663499543b535de0e61e0b67afce27f2d637f938";
    hash = "sha256-mE0mFTew2LZG8k9ShHay8oSqrGF8LILjg3V2vgEkefI=";
  };
  nqptp = fetchFromGitHub {
    owner = "mikebrady";
    repo = "nqptp";
    rev = "1.2.6";
    hash = "sha256-bU7eTNnPhBA+XTW0SCps/iUCGuxObnv72/Lm+yKEgao=";
  };
  shairport-sync-metadata-reader = fetchFromGitHub {
    owner = "mikebrady";
    repo = "shairport-sync-metadata-reader";
    rev = "99a59358a91cd8eed393269514d6a35050093cf5";
    hash = "sha256-Q3qTCMkSox1eE/1yYqc1ji5eTx46Xr0k2Z0YQ3QfCcY=";
  };

  # squeezelite at the commit hifiberry-squeezelite 2.0.0.1566 builds
  squeezelite = fetchFromGitHub {
    owner = "ralph-irving";
    repo = "squeezelite";
    rev = "6d571de8fa6dfff23a5a0cbb2c81b402d2c30c31";
    hash = "sha256-rwiRZaadku4xAAQiloghnmMtRlflgGJ8prEUQJsuR8c=";
  };

  # MPD 0.24.13, the version hifiberry-mpd 0.24.13.x builds
  mpd = fetchFromGitHub {
    owner = "MusicPlayerDaemon";
    repo = "MPD";
    rev = "v0.24.13";
    hash = "sha256-ZcSMd+PhO8sWGA96GtwM3ykPS//8SpqDh9lLh3unB8Q=";
  };

  # python3-usagecollector
  usagecollector = fetchFromGitHub {
    owner = "hifiberry";
    repo = "usagecollector";
    rev = "50896d7318e386d3a26d2169e74f6f8655cabf05";
    hash = "sha256-5dxX69ZRWaZ9daGiSKniKY+EFL5G3iuit38ZSsTW/cs=";
  };

  # nowplaying-sdl 1.0.0 (local SDL display)
  nowplaying-sdl = fetchFromGitHub {
    owner = "hifiberry";
    repo = "nowplaying-sdl";
    rev = "67f16bde1117a082b774d51cacb2290103b38b6f";
    hash = "sha256-nS3JpxTzAQxQ70SZmGrhY/pFPxtevbxexCsK0GB08WU=";
  };

  # songcompare 1.0.1 (A/B listening comparison)
  songcompare = fetchFromGitHub {
    owner = "hifiberry";
    repo = "songcompare";
    rev = "a589698b98ba7ad1915e0b3a19b583ab50290967";
    hash = "sha256-BHD3chVQ5lNipL1A+1sNpROqd3/t9m7rUZ7Xqa2KOHw=";
  };
}
