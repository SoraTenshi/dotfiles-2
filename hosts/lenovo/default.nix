{
  config,
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

    kernelModules = ["acpi_call"];

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
        gfxmodeEfi = "1920x1080";
        theme = pkgs.fetchzip {
          # https://github.com/AdisonCavani/distro-grub-themes
          url = "https://raw.githubusercontent.com/AdisonCavani/distro-grub-themes/master/themes/lenovo.tar";
          hash = "sha256-6ZevSnSNJ/Q67DTNJj8k4pjOjWZFj0tG0ljG3gwbLuc=";
          stripRoot = false;
        };
      };
    };
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver # iHD
        libva
        libvdpau
        libvdpau-va-gl
        (vaapiIntel.override {enableHybridCodec = true;}) # i965 (older but works better for Firefox/Chromium)
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

    xserver = {
      enable = true;

      displayManager = {
        autoLogin = {
          enable = true;
          user = "rxyhn";
        };

        defaultSession = "none+awesome";
        lightdm.enable = true;
      };

      dpi = 189;
      exportConfiguration = true;
      layout = "us";

      libinput = {
        enable = true;
        touchpad = {naturalScrolling = true;};
      };

      windowManager = {
        awesome = {
          enable = true;
          luaModules = lib.attrValues {
            inherit (pkgs.luaPackages) lgi ldbus luadbi-mysql luaposix;
          };
        };
      };
    };
  };

  environment = {
    sessionVariables = {_JAVA_AWT_WM_NONREPARENTING = "1";};
    variables = {__GL_MaxFramesAllowed = "0";};

    systemPackages = with pkgs; [
      acpi
      brightnessctl
      docker-client
      docker-compose
      docker-credential-helpers
      libva-utils
      ocl-icd
      virt-manager
      vulkan-tools
    ];
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
