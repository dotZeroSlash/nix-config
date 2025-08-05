{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };
in
{
  #############################################################
  # SYSTEM BASICS
  #############################################################

  # Include hardware scan results
  imports = [ ./hardware-configuration.nix ];

  # System version - don't change this after initial installation
  system.stateVersion = "24.11";

  # Package configuration
  nixpkgs.config.allowUnfree = true;

  #############################################################
  # BOOT CONFIGURATION
  #############################################################

  boot = {
    # Bootloader
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # NVIDIA-related boot settings
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelModules = [ "nvidia" ];
    kernelParams = [ "nvidia-drm.modeset=1" ];
  };

  #############################################################
  # LOCALIZATION & TIME
  #############################################################

  # Time zone
  time.timeZone = "America/Los_Angeles";

  # Locale settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  #############################################################
  # NETWORKING
  #############################################################

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [ 3000 11434 12393 8000 5000 6969 19783 3001 ];
    };
  };

  #############################################################
  # GRAPHICS & DISPLAY
  #############################################################

  # X11 configuration
  services.xserver = {
    enable = true;

    # Display manager and desktop environment
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };

    # NVIDIA drivers
    videoDrivers = ["nvidia"];
  };

  # Hardware graphics settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA specific configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    forceFullCompositionPipeline = true;
  };

  #############################################################
  # AUDIO
  #############################################################

  # Audio configuration
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    # Uncomment if needed:
    # jack.enable = true;
  };

  #############################################################
  # USERS
  #############################################################

  users.users.yumlabs = {
    isNormalUser = true;
    description = "yumlabs";
    extraGroups = [ "networkmanager" "wheel" "docker" "plugdev" "adbusers" ];
    packages = with pkgs; [];
  };

  #############################################################
  # SYSTEM SERVICES
  #############################################################

  services = {
    # SSH server
    openssh.enable = true;

    # Printing (disabled)
    printing.enable = false;

    # USB device rules
    udev.extraRules = ''
      # Android devices
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
    '';

    # Ollama service
    ollama = {
      enable = true;
      host = "0.0.0.0";
      package = unstable.ollama;
      acceleration = "cuda";
    };
  };

  # Docker virtualization
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Firefox (disabled)
  programs.firefox.enable = false;

  #############################################################
  # PACKAGES
  #############################################################

  environment.systemPackages = with pkgs; [
    # Development tools
    rustup
    git
    gcc
    nodejs
    bun
    waydroid
    # Libraries and utilities
    wl-clipboard
    sqlite
    openssh
    ffmpeg_6-full
    jq

    # Applications
    # unstable.godot
    unstable.ollama
    unstable.bolt-launcher

    # jetbrains.idea-community

   # openjdk11
   # gradle
   # maven

    liquidctl
    appimage-run
    # rustdesk-flutter
    discord
    vscode
    yazi
    ghostty
    # Fonts and visual elements
    hackgen-nf-font

    # Mobile development
    android-tools
    usbutils

    # System libraries
    nss
  ];

  #############################################################
  # ENVIRONMENT & RUNTIME
  #############################################################

  # Environment variables
  environment.variables = {
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudatoolkit}/lib64:$LD_LIBRARY_PATH";
    PATH = [
      "\${HOME}/.cargo/bin"
    ];
    CUDA_VISIBLE_DEVICES = "0";
    # Commented out options that you might want to enable later:
    # OLLAMA_NUM_PARALLEL= "4";
    # OLLAMA_KV_CACHE_TYPE= "mmapped";
  };

  environment.shellAliases = {
  nix-update = "sudo nix-channel --update";
  nix-edit = "sudo nvim /etc/nixos/configuration.nix";
  nix-rb = "sudo nixos-rebuild switch";
  nix-garb = "sudo nix-collect-garbage -d";
  };

  # nix-ld configuration for compatibility with non-NixOS binaries
  programs.nix-ld = {
    enable = true; # may need to revert this back at a later date if wanting to use cuda packages?
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      openssl
     cudaPackages.cuda_cudart
     cudaPackages.cuda_cupti
     cudaPackages.cuda_nvrtc
     cudaPackages.cudatoolkit
     cudaPackages.cudnn
      zlib
      glib
    ];
  };

  # Ollama environment variables
  systemd.services.ollama.environment = {
    "OLLAMA_MAX_RAM" = "6GiB";
    "CUDA_VISIBLE_DEVICES" = "0";
  };

  #############################################################
  # SYSTEM PERFORMANCE
  #############################################################

  # Swap for memory management
  swapDevices = [
    {
      device = "/var/swap";
      size = 8192; # 8GB swap file
    }
  ];
}
