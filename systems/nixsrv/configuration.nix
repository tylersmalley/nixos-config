{ config, lib, pkgs, ... }:
let
  libx = import ./lib.nix { inherit lib; };
  inherit (libx) mkBinds;
  mkContainer = libx.mkContainer {
    ephemeral = true;
    autoStart = true;
    enableTun = true;
    privateNetwork = true;
    hostBridge = "br0";

    config = _: {
      nixpkgs.pkgs = pkgs;
      networking.interfaces.eth0.useDHCP = true;
      services.tailscale.enable = true;
      system.stateVersion = "23.05";
    };
  };
in
{
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "nixsrv";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "br0" ];
  };

  networking.interfaces.ens18.useDHCP = true;

  networking.bridges.br0 = { interfaces = [ ]; };
  networking.interfaces.br0.ipv4.addresses = [{ address = "172.16.0.1"; prefixLength = 24; }];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "ens18";
    extraCommands = ''
      iptables -A FORWARD -i br0 -m state --state RELATED,ESTABLISHED -j ACCEPT

      iptables -A FORWARD -i br0 -d 10.0.0.0/8 -j DROP
      iptables -A FORWARD -i br0 -d 172.16.0.0/12 -j DROP
      iptables -A FORWARD -i br0 -d 10.0.0.0/16 -j DROP
    '';
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      dhcp-range = "172.16.0.2,172.16.0.254,24h";
      listen-address = "172.16.0.1";
    };
  };

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /pool/downloads/complete 0777 root root -"
    "d /pool/downloads/incomplete 0777 root root -"

    "d /pool/media/tv 0777 root root -"
    "d /pool/media/movies 0777 root root -"

    "d /pool/container-data/sabnzbd/config 0755 root root -"
    "d /pool/container-data/sabnzbd/tailscale 0755 root root -"

    "d /pool/container-data/sonarr/config 0755 root root -"
    "d /pool/container-data/sonarr/tailscale 0755 root root -"

    "d /pool/container-data/radarr/config 0755 root root -"
    "d /pool/container-data/radarr/tailscale 0755 root root -"

    "d /pool/container-data/jellyfin/data 0755 root root -"
    "d /pool/container-data/jellyfin/tailscale 0755 root root -"

    "d /pool/container-data/plex/data 0755 root root -"
    "d /pool/container-data/plex/tailscale 0755 root root -"

    "d /pool/container-data/ombi/config 0755 root root -"
    "d /pool/container-data/ombi/tailscale 0755 root root -"


    "d /pool/container-data/jellyseerr/data 0755 root root -"
    "d /pool/container-data/jellyseerr/tailscale 0755 root root -"

    "d /pool/container-data/vaultwarden/data 0755 root root -"
    "d /pool/container-data/vaultwarden/tailscale 0755 root root -"

    "d /pool/container-data/whoogle/config 0755 root root -"
    "d /pool/container-data/whoogle/tailscale 0755 root root -"

    "d /pool/container-data/searx/config 0755 root root -"
    "d /pool/container-data/searx/tailscale 0755 root root -"

    "d /pool/container-data/adguard/config 0755 root root -"
    "d /pool/container-data/adguard/tailscale 0755 root root -"

    "d /pool/container-data/changedetection-io/config 0755 root root -"
    "d /pool/container-data/changedetection-io/tailscale 0755 root root -"

    "d /pool/container-data/syncthing/config 0755 root root -"
    "d /pool/container-data/syncthing/data 0755 root root -"
    "d /pool/container-data/syncthing/tailscale 0755 root root -"
  ];

  containers.sabnzbd = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/sabnzbd:/pool/container-data/sabnzbd/config"
      "/var/lib/tailscale:/pool/container-data/sabnzbd/tailscale"
      "/downloads:/pool/downloads"
    ];
    config = _: {
      users.users.sabnzbd = {
        extraGroups = [ "container" ];
      };
      services.sabnzbd.enable = true;
      services.sabnzbd.package = pkgs.unstable.sabnzbd;
      systemd.tmpfiles.rules = [
        "d /var/lib/sabnzbd 0755 sabnzbd sabnzbd -"
      ];
    };
  };

  containers.sonarr = mkContainer {
    bindMounts = mkBinds [
      "/config:/pool/container-data/sonarr/config"
      "/var/lib/tailscale:/pool/container-data/sonarr/tailscale"
      "/downloads:/pool/downloads"
      "/tv:/pool/media/tv"
    ];
    config = _: {
      services.sonarr.enable = true;
      services.sonarr.package = pkgs.unstable.sonarr;
      services.sonarr.dataDir = "/config";
      systemd.tmpfiles.rules = [
        "d /config 0755 sonarr sonarr -"
      ];
    };
  };

  containers.radarr = mkContainer {
    bindMounts = mkBinds [
      "/config:/pool/container-data/radarr/config"
      "/var/lib/tailscale:/pool/container-data/radarr/tailscale"
      "/downloads:/pool/downloads"
      "/movies:/pool/media/movies"
    ];
    config = _: {
      services.radarr.enable = true;
      services.radarr.dataDir = "/config";
      services.radarr.package = pkgs.unstable.radarr;
      systemd.tmpfiles.rules = [
        "d /config 0755 radarr radarr -"
      ];
    };
  };

  containers.jellyfin = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/jellyfin:/pool/container-data/jellyfin/data"
      "/var/lib/tailscale:/pool/container-data/jellyfin/tailscale"
      "/media:/pool/media"
    ];
    config = _: {
      services.jellyfin.enable = true;
      services.jellyfin.openFirewall = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/jellyfin 0755 jellyfin jellyfin -"
      ];
    };
  };

  containers.jellyseerr = mkContainer {
    bindMounts = mkBinds [
      #"/var/lib/jellyseerr:/pool/container-data/jellyseerr/data"
      "/var/lib/tailscale:/pool/container-data/jellyseerr/tailscale"
    ];
    config = _: {
      services.jellyseerr.enable = true;
      services.jellyseerr.openFirewall = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/jellyseerr 0755 jellyseerr jellyseerr -"
      ];
    };
  };

  containers.syncthing = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/syncthing:/pool/container-data/syncthing"
      "/var/lib/tailscale:/pool/container-data/syncthing/tailscale"
    ];
    config = _: {
      services.syncthing.enable = true;
      services.syncthing.dataDir = "/var/lib/syncthing/data";
      services.syncthing.configDir = "/var/lib/syncthing/config";
      systemd.tmpfiles.rules = [
        "d /var/lib/jellyseerr 0755 jellyseerr jellyseerr -"
      ];
    };
  };


  containers.vaultwarden = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/bitwarden_rs:/pool/container-data/vaultwarden/data"
      "/var/lib/tailscale:/pool/container-data/vaultwarden/tailscale"
    ];
    config = _: {
      imports = [
        ./vaultwarden.enc.nix
      ];
      services.vaultwarden.enable = true;
      services.vaultwarden.package = pkgs.unstable.vaultwarden;
      services.vaultwarden.webVaultPackage = pkgs.unstable.vaultwarden.webvault;
      services.vaultwarden.config = {
        SIGNUPS_ALLOWED = false;
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/vaultwarden 0755 vaultwarden vaultwarden -"
      ];
    };
  };

  containers.searx = mkContainer {
    bindMounts = mkBinds [
      "/config:/pool/container-data/searx/config"
      "/var/lib/tailscale:/pool/container-data/searx/tailscale"
    ];
    config = _: {
      services.searx.enable = true;
      services.searx.settingsFile = "/config/settings.yml";
      systemd.tmpfiles.rules = [
        "d /var/lib/searx 0755 searx searx -"
      ];
    };
  };

  containers.adguard = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/AdGuardHome:/pool/container-data/adguard/config"
      "/var/lib/tailscale:/pool/container-data/adguard/tailscale"
    ];
    config = _: {
      services.adguardhome.enable = true;
      services.adguardhome.openFirewall = true;
      services.adguardhome.settings = {
        bind_port = 3000;
        bind_host = "0.0.0.0";
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/AdGuardHome 0755 adguardhome adguardhome -"
      ];
    };
  };

  containers.changedetection = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/tailscale:/pool/container-data/changedetection-io/tailscale"
      "/datastore:/pool/container-data/changedetection-io/config"
    ];
    extraFlags = [
      "--system-call-filter=keyctl"
      "--system-call-filter=bpf"
    ];
    additionalCapabilities = [ "all" ];
    config = _: {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers = {
        changedetection-io-playwright = {
          image = "browserless/chrome";
          environment = {
            SCREEN_WIDTH = "1920";
            SCREEN_HEIGHT = "1024";
            SCREEN_DEPTH = "16";
            ENABLE_DEBUGGER = "false";
            PREBOOT_CHROME = "true";
            CONNECTION_TIMEOUT = "300000";
            MAX_CONCURRENT_SESSIONS = "10";
            CHROME_REFRESH_TIME = "600000";
            DEFAULT_BLOCK_ADS = "true";
            DEFAULT_STEALTH = "true";
          };
          ports = [
            "127.0.0.1:3000:3000"
          ];
          extraOptions = [ "--network=bridge" ];
        };
        changedetection = {
          image = "dgtlmoon/changedetection.io";
          environment = {
            PLAYWRIGHT_DRIVER_URL = "ws://127.0.0.1:3000/?stealth=1&--disable-web-security=true";
          };
          extraOptions = [ "--network=bridge" ];
          autoStart = true;
          ports = [ "127.0.0.1:5000:5000" ];
        };
      };
    };
  };

  containers.whoogle = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/tailscale:/pool/container-data/whoogle/tailscale"
    ];
    extraFlags = [
      "--system-call-filter=keyctl"
      "--system-call-filter=bpf"
    ];
    additionalCapabilities = [ "all" ];
    config = _: {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers = {
        whoogle = {
          image = "benbusby/whoogle-search";
          autoStart = true;
          ports = [ "127.0.0.1:5000:5000" ];
        };
      };
    };
  };

  # containers.immich = mkContainer {
  #   bindMounts = mkBinds [
  #     "/var/lib/tailscale:/pool/container-data/immich/tailscale"
  #   ];
  #   extraFlags = [
  #     "--system-call-filter=keyctl"
  #     "--system-call-filter=bpf"
  #   ];
  #   additionalCapabilities = [ "all" ];
  #   config = _: {
  #     virtualisation.docker.enable = true;
  #     virtualisation.oci-containers.backend = "docker";
  #     virtualisation.oci-containers.containers = {
  #       immich = {
  #         image = "ghcr.io/imagegenius/immich:latest";
  #         autoStart = true;
  #         ports = [ "127.0.0.1:8080:8080" ];
  #       };
  #     };
  #   };
  # };
  # containers.plex = mkContainer {
  #   bindMounts = mkBinds [
  #     "/var/lib/plex:/pool/container-data/plex/data"
  #     "/var/lib/tailscale:/pool/container-data/plex/tailscale"
  #     "/media:/pool/media"
  #   ];
  #   config = _: {
  #     services.plex.enable = true;
  #     systemd.tmpfiles.rules = [
  #       "d /var/lib/plex 0755 plex plex -"
  #     ];
  #   };
  # };

  # containers.ombi = mkContainer {
  #   bindMounts = mkBinds [
  #     "/var/lib/ombi:/pool/container-data/ombi/config"
  #     "/var/lib/tailscale:/pool/container-data/ombi/tailscale"
  #   ];
  #   config = _: {
  #     services.ombi.enable = true;
  #     systemd.tmpfiles.rules = [
  #       "d /var/lib/ombi 0755 ombi ombi -"
  #     ];
  #   };
  # };

}
