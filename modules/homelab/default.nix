{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab;
in {
  options.services.homelab = with lib; {
    enable = mkEnableOption "homelab services";
    
    mediaPath = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Base path for media storage";
    };

    nfsServer = mkOption {
      type = types.str;
      description = "NFS server hostname or IP";
    };

    nfsShare = mkOption {
      type = types.str;
      description = "NFS share path on server";
    };
  };

  config = lib.mkIf cfg.enable {
    # System packages needed for services
    environment.systemPackages = with pkgs; [
      # Core media packages
      plex
      sonarr
      radarr
      prowlarr
      sabnzbd
      nzbhydra2
      
      # Support tools
      ffmpeg
      mediainfo
    ];

    # NFS client support
    services.rpcbind.enable = true;
    
    # NFS mount configuration
    fileSystems.${cfg.mediaPath} = {
      device = "${cfg.nfsServer}:${cfg.nfsShare}";
      fsType = "nfs";
      options = [
        "nofail"          # Don't fail boot if mount fails
        "soft"            # Return errors rather than hang
        "timeo=15"        # Timeout after 15 seconds
        "retrans=2"       # Number of retries before failure
        "rw"             # Mount read-write
        "x-systemd.automount"  # Automount on access
        "x-systemd.idle-timeout=600"  # Unmount after 10 minutes of inactivity
      ];
    };

    # Enable and configure media services
    services = {
      plex = {
        enable = true;
        openFirewall = true;
        user = "plex";
        group = "plex";
        dataDir = "/var/lib/plex";
      };

      sonarr = {
        enable = true;
        user = "sonarr";
        group = "sonarr";
        dataDir = "/var/lib/sonarr";
      };

      radarr = {
        enable = true;
        user = "radarr";
        group = "radarr";
        dataDir = "/var/lib/radarr";
      };

      prowlarr = {
        enable = true;
        user = "prowlarr";
        group = "prowlarr";
        dataDir = "/var/lib/prowlarr";
      };
    };

    # Open required ports in firewall
    networking.firewall = {
      allowedTCPPorts = [
        32400  # Plex
        8989   # Sonarr
        7878   # Radarr
        9696   # Prowlarr
        8080   # SABnzbd
        5076   # NZBHydra2
      ];
    };

    # Create shared media group and add service users to it
    users.groups.media = {};

    users.users = {
      plex.extraGroups = [ "media" ];
      sonarr.extraGroups = [ "media" ];
      radarr.extraGroups = [ "media" ];
      prowlarr.extraGroups = [ "media" ];
    };

    # Ensure media directory has correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaPath} 0775 root media - -"
    ];
  };
}
