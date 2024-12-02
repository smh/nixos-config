{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware/vm-aarch64.nix
    ../modules/vmware-guest.nix
    ../modules/homelab
    ./vm-shared.nix
  ];

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  services.homelab = {
    enable = true;
    nfsServer = "blackhole.lan";
    nfsShare = "/data/media";
    mediaPath = "/mnt/media";
  };

  # nixarr = {
  #   enable = true;
  #   mediaDir = "/mnt/media";
  #   stateDir = "/var/lib/nixarr/.state";


  #   prowlarr.enable = true;
  #   radarr.enable = true;
  #   readarr.enable = true;
  #   sonarr.enable = true;
  # };


  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };
}
