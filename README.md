# Overview
An Artix Linux (OpenRC) installation script that can be used to install and configure Artix Linux (OpenRC) with my preferred setup.

Some major/noteworthy differences from common configurations:

- opendoas is used in place of sudo
- EXT4 fast_commit mode is enabled by default
- makepkg is configured for better than stock performance and uses more space-efficient compression
- dash is used as the system and login shell
- zsh (with a custom zshrc) is used as the defualt KDE (Konsole/Yakuake) shell
- Plasma Wayland is configured for speed and security by default (disabled Klipper, Baloo, session restore, etc.)

# Usage
Upon loading up the official Artix OpenRC base ISO (tested on weekly base images only), logging in, connecting to the internet, and switching to the root user, run:

```
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

After running the script, it will ask you some questions about your desired configuration. Answer them and then the installation will complete automatically.

# Supported Devices
Generic:

- Most x86_64 desktops, laptops, and servers

Special:

- ASUS Zephyrus G14 (2020) (bugged - cannot boot current Artix ISO images - can install from 2022-01-23 ISO)
