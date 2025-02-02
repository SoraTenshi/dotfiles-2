{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./nvidia.nix

    # Shared configuration across all machines
    ../shared
    ../shared/users/rxyhn.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "i915.force_probe=46a6"
      "i915.enable_psr=0"
      "i915.enable_guc=2"
      "i8042.direct"
      "i8042.dumbkbd"
    ];

    supportedFilesystems = ["btrfs"];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      systemd-boot.enable = false;

      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        enableCryptodisk = true;
        configurationLimit = 3;
      };
    };
  };

  # OpenGL and accelerated video playback
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
        vaapiIntel
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
        libva
        libvdpau-va-gl
        vaapiIntel
        vaapiVdpau
      ];
    };

    bluetooth = {
      enable = true;
      package = pkgs.bluez;
    };

    enableRedistributableFirmware = true;
    pulseaudio.enable = false;
  };

  # compresses half the ram for use as swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services = {
    btrfs.autoScrub.enable = true;
    acpid.enable = true;
    thermald.enable = true;
    upower.enable = true;

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 0;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "Hyprland";
          user = "rxyhn";
        };
        default_session = initial_session;
      };
    };

    # add hyprland to display manager sessions
    xserver.displayManager.sessionPackages = [inputs.hyprland.packages.${pkgs.system}.default];
  };

  # selectable options
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # enable hyprland
  programs.hyprland.nvidiaPatches = true;

  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
  };

  environment = {
    systemPackages = with pkgs; [
      acpi
      brightnessctl
      cudaPackages_11.cudatoolkit
      cudaPackages_11.cudnn
      docker-client
      docker-compose
      docker-credential-helpers
      libva-utils
      ocl-icd
      qt5.qtwayland
      qt5ct
      virt-manager
      vulkan-tools
    ];

    variables = {
      NIXOS_OZONE_WL = "1";
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      WLR_BACKEND = "vulkan";
      WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      WLR_DRM_NO_ATOMIC = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };

  virtualisation = {
    spiceUSBRedirection.enable = true;

    docker = {
      enable = true;
      enableNvidia = true;
    };

    podman = {
      enable = true;
      enableNvidia = true;
      extraPackages = with pkgs; [
        skopeo
        conmon
        runc
      ];
    };

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf = {
          enable = true;
          packages = with pkgs; [OVMFFull.fd];
        };
        swtpm.enable = true;
      };
    };
  };

  system.stateVersion = lib.mkForce "22.11"; # DONT TOUCH THIS
}
