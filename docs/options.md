# Options

Every option of the HiFiBerryOS module. Generated from the module by
`nix build .#options-doc`; do not edit by hand.

## hifiberry\.enable



Whether to enable HiFiBerryOS (PipeWire, AudioControl, configurator, web interface, players)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.packages



The HiFiBerryOS package set to use\.



*Type:*
attribute set



*Default:*

```nix
import ../pkgs { inherit pkgs; }
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.audiocontrol\.secretsFile

A ` secrets.txt ` (see secrets\.txt\.sample in hifiberry/acr) with the API
credentials AudioControl bakes into its binary: Last\.fm, TheAudioDB and
HiFiBerry’s Spotify OAuth proxy\. Without it everything works except
scrobbling, TheAudioDB lookups and linking a Spotify account\. The file
is copied into the Nix store\.



*Type:*
null or absolute path



*Default:*

```nix
null
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.binaryCache\.enable



Add the cache this project’s CI fills (sweenu\.cachix\.org) to the
device’s Nix substituters, so rebuilding on the device downloads the
HiFiBerry packages instead of compiling them\. They match when the
system uses the same nixpkgs as this flake, as ` lib.nixosSystem `
does\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.bleProvisioning\.enable



Whether to enable Wi-Fi provisioning over Bluetooth LE\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.bluetooth\.enable



Whether to enable Bluetooth audio (hifiberry-bluetooth)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.dsp\.enable



Whether to enable the DSP toolkit (sigmatcpserver) and DSP profiles\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.initialPassword



Initial password of the player user, for SSH and console access on the
first boot\. Set to null when you configure ` users.users.<user> ` yourself\.



*Type:*
null or string



*Default:*

```nix
"hifiberry"
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.kiosk\.enable



Whether to enable kiosk mode: a full-screen browser on the HDMI output, started at boot,
showing the web interface’s now-playing page\. SSH and the web interface
are unaffected\. The browser runs as ` hifiberry.user ` in cage on tty1
(` services.cage `); set ` services.cage.program ` to run something else
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.kiosk\.package



The chromium package to use\.



*Type:*
package



*Default:*

```nix
pkgs.chromium
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.kiosk\.extraArguments



Additional command line arguments for Chromium\. Chromium reads only
the last ` --enable-features `, so repeat ` NetworkServiceInProcess2 ` in
one you add\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "--enable-features=NetworkServiceInProcess2,OverlayScrollbar"
]
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.kiosk\.ignoreHdmiInput



Tell libinput to ignore the HDMI (CEC) input device\. The Raspberry Pi
reports it as an input device, which otherwise leaves a mouse cursor
stuck in the middle of the screen when no mouse is plugged in\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.kiosk\.scale



Zoom factor, applied as the scale of the screen\. A TV often reports a
wrong physical size, so raise it for large or distant screens: about
1\.0 for a 24" monitor, 1\.2-1\.3 for a 40-50" TV, 1\.4-1\.5 for a 55-70"
TV\.



*Type:*
positive integer or floating point number, meaning >0



*Default:*

```nix
1.3
```



*Example:*

```nix
1.5
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.kiosk\.url



Page to display\. ` ?dark ` forces the dark theme of the now-playing
pages; leave it out to follow the web interface’s theme\.



*Type:*
string



*Default:*

```nix
"http://localhost/now-playing-minimal?dark"
```



*Example:*

```nix
"http://localhost/now-playing"
```

*Declared by:*
 - [modules/kiosk\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/kiosk.nix)



## hifiberry\.openFirewall



Open the firewall for the web interface (80) and for each enabled
player: Sendspin (8928), MPD (6600), and for AirPlay, Spotify Connect,
Roon, Squeezelite and AES67, which pick ports at runtime, their fixed
ports plus the ephemeral range 32768-60999\. mDNS is opened by Avahi\.
Has no effect while ` networking.firewall.enable ` is false\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.openssh\.enable



Whether to enable SSH access\. Password logins are accepted only while the player user has
no ` openssh.authorizedKeys `, since the initial password is public
\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.players\.aes67\.enable



Whether to enable AES67 receiver\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.aes67\.autoStart



Enable the AES67 receiver service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.aes67.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.analogRecognition\.enable



Whether to enable analog input with track recognition (songrec)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.analogRecognition\.autoStart



Enable the analog input with track recognition (songrec) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.analogRecognition.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.analoginput\.enable



Whether to enable analog input pass-through\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.analoginput\.autoStart



Enable the analog input pass-through service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.analoginput.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.librespot\.enable



Whether to enable Spotify Connect (librespot)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.librespot\.autoStart



Enable the Spotify Connect (librespot) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.librespot.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.mpd\.enable



Whether to enable Music Player Daemon (local and network music files)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.mpd\.autoStart



Enable the Music Player Daemon (local and network music files) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.mpd.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.raat\.enable



Whether to enable Roon Ready (RAAT)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.raat\.autoStart



Enable the Roon Ready (RAAT) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.raat.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.sendspin\.enable



Whether to enable Music Assistant (Sendspin)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.sendspin\.autoStart



Enable the Music Assistant (Sendspin) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.sendspin.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.sendspin\.protocol



Which Sendspin protocol the player speaks\.

` legacy ` is the pre-1\.0 sendspin-cpp that HiFiBerry’s own
hifiberry-sendspin pins, and is what every released Music Assistant
talks to\. Those servers treat it as a legacy client: playback works,
but the stream is torn down on pause and can collapse shortly after
resuming, and volume changes may not reach the speaker\.

` v1 ` builds sendspin-cpp 0\.9, which speaks Sendspin 1\.0: encrypted
connections, a persistent client identity and pairing, and the timing
fields that fix the behaviour above\. It needs a server on
aiosendspin 10 or newer — Music Assistant 2\.11 or later\. Against an
older server the Noise handshake fails and the player never connects,
so this stays off until your server is new enough\.



*Type:*
one of “legacy”, “v1”



*Default:*

```nix
"legacy"
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.shairport\.enable



Whether to enable AirPlay (shairport-sync)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.shairport\.autoStart



Enable the AirPlay (shairport-sync) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.shairport.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.squeezelite\.enable



Whether to enable Squeezebox/Lyrion Music Server client (squeezelite)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.squeezelite\.autoStart



Enable the Squeezebox/Lyrion Music Server client (squeezelite) service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.squeezelite.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.usbaudio\.enable



Whether to enable USB audio gadget input\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.players\.usbaudio\.autoStart



Enable the USB audio gadget input service in the player user’s session on
the first boot (what installing the package does on HiFiBerryOS)\.
The web interface can switch it on and off afterwards\.



*Type:*
boolean



*Default:*

```nix
config.hifiberry.players.usbaudio.enable
```

*Declared by:*
 - [modules/players/default\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/players/default.nix)



## hifiberry\.roomeq\.enable



Whether to enable the RoomEQ room correction service\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.setup\.skipWizard



Whether to enable skipping the web interface’s first-run setup wizard\. Declare what it
would ask here instead: ` hifiberry.setup.systemName `,
` hifiberry.setup.webAuth `, ` hifiberry.soundcard ` and
` hifiberry.players.*.enable `\. Anything left undeclared keeps its
default and can still be changed from the web interface’s settings
\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.setup\.systemName



The device name shown in Music Assistant and the web interface\. The
hostname (and so the ` .local ` mDNS name) is derived from it as the
configurator does: “Bedroom speakers” becomes ` bedroom-speakers `\.
When set, the name is fixed by the configuration and can no longer be
changed from the web interface\. ` null ` leaves it to the setup wizard
and the system settings (default ` hifiberry `)\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"Bedroom speakers"
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.setup\.webAuth\.hashedPassword



argon2id hash of the device password, required for the ` risky ` and
` all ` policies\. Create one with
` nix run github:sweenu/hifiberry-nixos#hash-password `\. The hash
ends up in the Nix store; use ` hashedPasswordFile ` to keep it out\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.setup\.webAuth\.hashedPasswordFile



Path, read at boot, to a file holding the argon2id hash (for
example from sops-nix or agenix)\. Takes precedence over
` hashedPassword `\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/run/secrets/hifiberry-web-password-hash"
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.setup\.webAuth\.protection



Which web interface actions need the device password
(hifiberry-auth’s protection policy): ` off ` (none), ` risky `
(system changes: network, name, installs, resets) or ` all ` (the
whole interface)\. Applied at every boot, together with the
password, replacing what was set from the web interface\. ` null `
leaves both to the setup wizard and the web interface\.



*Type:*
null or one of “off”, “risky”, “all”



*Default:*

```nix
null
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.soundcard



Device tree overlay of the HiFiBerry sound card, as it would appear
after ` dtoverlay= ` in config\.txt (for example ` hifiberry-dacplus `,
` hifiberry-dacplusadcpro `, ` hifiberry-digi-pro `, ` hifiberry-amp100,automute `)\.

` null ` keeps HiFiBerryOS’ behaviour: the card is detected on boot
(HAT EEPROM, I2C), the overlay is written to /boot/firmware/hifiberry\.txt,
which config\.txt includes, and the device reboots once\. Setting the
overlay here puts it in config\.txt itself, so no detection reboot is
needed and the setting survives ` nixos-rebuild `\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"hifiberry-dacplus"
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.uid



UID of the player user\.



*Type:*
signed integer



*Default:*

```nix
1000
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.user



The user whose systemd user session runs PipeWire and the players, as
HiFiBerryOS does (written to /etc/hifiberry\.user)\. Lingering is enabled
for this user so its services start at boot without a login\.



*Type:*
string



*Default:*

```nix
"hifiberry"
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.vuMeter\.enable



Whether to enable the VU meter service\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)



## hifiberry\.webmcp\.enable



Whether to enable the AudioControl MCP server (acr-webmcp)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/options\.nix](https://github.com/sweenu/hifiberry-nixos/blob/main/modules/options.nix)


