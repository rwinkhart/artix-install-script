# WARNING
With the recent release of Plasma 6, this script needs some restructuring. Do not use it until this message disappears.

# Overview
An Artix Linux (OpenRC) installation script that can be used to install and configure Artix Linux (OpenRC) with _**my**_ preferred setup.

Some major/noteworthy differences from common configurations:

- opendoas is used in place of sudo
- EXT4 fast_commit mode is enabled by default
- makepkg is configured for better than stock performance and uses more space-efficient compression
- dash is used as the system and login shell
- zsh (with a custom zshrc) is used as the defualt KDE (Konsole/Yakuake) shell
- Plasma Wayland is configured for speed and security by default (disabled Klipper, Baloo, session restore, etc.)

# Usage
Upon loading up the official Artix OpenRC base ISO (tested on weekly base images only), logging in as root, and connecting to the internet, run:

```
pacman -Sy git
git clone --depth 1 https://github.com/rwinkhart/artix-install-script
cd artix-install-script
./install.sh
```

After running the script, it will ask some questions about your desired configuration. Answer them and then the installation will complete automatically.

# Supported Devices
Generic:
- Most x86_64 desktops and laptops

Special:
- ASUS Zephyrus G14 (2020)
