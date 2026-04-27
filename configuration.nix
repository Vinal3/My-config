{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
   enable = true;
   useOSProber = true;
   device = "/dev/sda";
   default = 2;
  };   

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Yekaterinburg";
  i18n.defaultLocale = "ru_RU.UTF-8";

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.thakur = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "i2c" "libvirtd" "kvm" "input" ];
      packages = with pkgs; [
        tree
      ];
    };

  users.groups.i2c = {};
  hardware.i2c.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.udisks2.enable = true;
  nixpkgs.config.allowUnfree = true;


  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Для ускорения видео на i5-3570
      intel-vaapi-driver
      libvdpau-va-gl

      vulkan-loader # vl
      vulkan-validation-layers # vl
      vulkan-tools # vl
    ];
  };

  hardware.nvidia = {
   modesetting.enable = true;
   open = false;
   powerManagement.enable = true;
   nvidiaSettings = false;
  }; 
     
  # Права
  security.sudo.extraRules = [{
    users = [ "thakur" ];
    commands = [{ command = "/run/current-system/sw/bin/cpupower"; options = [ "NOPASSWD" ]; }];
  }];

  # You can use https://search.nixos.org/
  environment.systemPackages = with pkgs; [
      vim
      git
      brave
      wget
      hyprland
      ly
      kitty
      telegram-desktop
      discord
      obs-studio
      hyprshot
      mpv
      steam-run
      unzip
      wine
      winetricks
      yazi
      ddcutil
      i2c-tools
      vscodium

      # Python
      python3
      direnv
      (python3.withPackages (ps: with ps; [ 
        numpy
      ]))

      # CS 2
      mesa-demos
      vulkan-tools  
      gamemode
      gamescope

      winetricks
      bottles

      # menu
      rofi
      cliphist
      papirus-icon-theme
      adwaita-icon-theme
      playerctl
      wl-clipboard
      grim
      slurp
      hyprlock      
      linuxPackages.cpupower

      # VPN
      mihomo
      curl
      iproute2
      iptables
      
      # SUPER PANEL
      virt-manager
      qemu
      OVMFFull
      bridge-utils
      libvirt
      dmidecode
    
      # others
      lm_sensors
      nvtopPackages.nvidia
      stow      
      btop
      swww
      neovim
      mpvpaper
      waybar
      nwg-look
      bibata-cursors
      adwaita-icon-theme
      kdePackages.breeze-icons
      hicolor-icon-theme
      gnome-themes-extra
      arc-theme
      materia-theme
    ];
   
  # SUPER PANEL
  nixpkgs.overlays = [
    (final: prev: {
      # 1. Патчим QEMU (основное железо)
      qemu = prev.qemu.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Диски и приводы
          substituteInPlace hw/scsi/scsi-disk.c --replace "QEMU HARDDISK" "Samsung SSD 980 PRO"
          substituteInPlace hw/ide/atapi.c --replace "QEMU DVD-ROM" "ASUS DRW-24B1ST"
          substituteInPlace hw/ide/core.c --replace "QEMU HARDDISK" "WDC WD10EZEX-00BN5A0"
          
          # USB и Аудио
          substituteInPlace hw/usb/dev-storage.c --replace "QEMU USB HARDDISK" "USB Flash Drive"
          substituteInPlace hw/audio/hda-codec.c --replace "QEMU HDA Audio" "Realtek ALC892"
          
          # CPUID (KVMKVMKVM -> GenuineIntel)
          substituteInPlace target/i386/kvm/kvm.c --replace "KVMKVMKVM" "GenuineIntel"
          
          # PCI IDs (заменяем Red Hat 0x1b36/0x1af4 на Intel 0x8086)
          # Осторожно: это "ядерный" метод из Phantom
          find . -type f -name "*.c" -exec sed -i 's/0x1b36/0x8086/g' {} +
          find . -type f -name "*.c" -exec sed -i 's/0x1af4/0x8086/g' {} +
        '';
      });

      # 2. Патчим OVMFFull (Таблицы ACPI)
      # В 25.11 мы просто патчим сам пакет, libvirt подхватит его автоматически
      OVMFFull = prev.OVMFFull.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Убираем упоминания BOCHS и BXPC в таблицах BIOS
          find . -type f \( -name "*.c" -o -name "*.h" -o -name "*.asl" \) -exec sed -i 's/"BOCHS "/"INTEL "/g' {} +
          find . -type f \( -name "*.c" -o -name "*.h" \) -exec sed -i 's/"BXPC"/"AMII"/g' {} +
          
          # Подменяем версию EFI
          substituteInPlace MdeModulePkg/Core/Dxe/DxeMain.h --replace "EFI_SPECIFICATION_VERSION" "0x0002001E"
        '';
      });
    })
  ];



  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;
  programs.dconf.enable = true;  


  boot.initrd.kernelModules = [ "i915" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  environment.variables = {
    "WLR_DRM_DEVICES" = "/dev/dri/by-path/pci-0000:00:02.0"; # Intel
    "__GLX_VENDOR_LIBRARY_NAME" = "mesa";
  };  

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Cursor for Steam
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "22";
    XCURSOR_PATH = lib.mkForce "/run/current-system/sw/share/icons:$HOME/.icons:$HOME/.local/share/icons";

    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "22";

    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.etc."xdg/icons/default".source =
    "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic";

  programs.steam = {
    enable = true;

    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        bibata-cursors
        adwaita-icon-theme
        hicolor-icon-theme
      ];
    };
  };

  # Fonts
  fonts.fontconfig.enable = true;

  fonts.packages = with pkgs; [
   noto-fonts
   noto-fonts-color-emoji

   dejavu_fonts
   liberation_ttf
   freefont_ttf

   corefonts
   vista-fonts

   roboto
   inter
   jetbrains-mono
   fira-code

   nerd-fonts.jetbrains-mono
   nerd-fonts.fira-code
   nerd-fonts.hack

   font-awesome
   material-icons
  ];

  boot.kernelModules = [ "tun" "i2c-dev" "kvm-intel" ]; # vpn и SP
  networking.firewall.enable = false; # vpn
  networking.firewall.checkReversePath = false; # vpn

  # Python
  programs.direnv.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.desktopManager.xterm.enable = true;


  programs.gamemode.enable = true;
  programs.chromium.enable = true;
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  services.displayManager.ly.enable = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}

