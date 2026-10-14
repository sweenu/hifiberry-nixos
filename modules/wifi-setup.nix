# Wi-Fi from the SD card: write /boot/firmware/wifi.txt on the card's FAT
# partition (any computer can) and the next boot adds the network to
# NetworkManager, then deletes the file so the password does not stay on the
# FAT partition. The image ships wifi.txt.example as a template.
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
  config = lib.mkIf (cfg.enable && config.networking.networkmanager.enable) {
    systemd.services.hifiberry-wifi-setup = {
      description = "Add the Wi-Fi network from /boot/firmware/wifi.txt";
      wantedBy = [ "multi-user.target" ];
      before = [ "NetworkManager.service" ];
      unitConfig = {
        ConditionPathExists = "/boot/firmware/wifi.txt";
        RequiresMountsFor = "/boot/firmware";
      };
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
      };
      path = [
        pkgs.networkmanager
        pkgs.coreutils
      ];
      script = ''
        ssid= password=
        # Editors on Windows end lines with CRLF; also accept a missing final newline.
        while IFS= read -r line || [ -n "$line" ]; do
          line=''${line%$'\r'}
          case "$line" in
            ssid=*) ssid=''${line#ssid=} ;;
            password=*) password=''${line#password=} ;;
          esac
        done < /boot/firmware/wifi.txt

        if [ -z "$ssid" ]; then
          echo "wifi.txt has no ssid= line, leaving it in place" >&2
          exit 1
        fi

        security=()
        if [ -n "$password" ]; then
          security=(wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password")
        fi
        dir=/etc/NetworkManager/system-connections
        mkdir -p "$dir"
        # --offline writes the keyfile without NetworkManager running, with
        # NetworkManager's own escaping of the SSID and password.
        nmcli --offline connection add type wifi con-name "$ssid" ssid "$ssid" \
          connection.autoconnect yes "''${security[@]}" > "$dir/wifi-setup.nmconnection.tmp"
        mv "$dir/wifi-setup.nmconnection.tmp" "$dir/wifi-setup.nmconnection"

        rm /boot/firmware/wifi.txt
        echo "Added Wi-Fi network $ssid"
      '';
    };
  };
}
