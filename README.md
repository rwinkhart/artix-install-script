# Overview
An Artix Linux installation script that can be used to install and configure Artix Linux with my preferred setup.

Some major/noteworthy differences from common configurations:

- opendoas is used in place of sudo
- pipewire is used in place of pulseaudio
- OpenRC is the chosen init system
- EXT4 fast_commit mode is enabled by default
- makepkg is configured for better than stock performance
- a custom .bashrc with useful power management aliases is included
- a custom script (xcaffeine.sh) is included to keep the screen awake during the use of whitelisted applications
- ...all of this and more on KDE Plasma X11

# Usage
Upon loading up the official Artix base ISO (tested on weekly base images only), logging in, connecting to the internet, and switching to the root user, run:

```
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

After running the script, it will ask you some questions about your desired configuration. Answer them and then the installation will complete automatically.

# Supported Devices
Generic:

- Most x86_64 desktops, laptops, and servers

Coming soon:

- ASUS laptops (2020-2022) via a built-in script in /etc/local.d and [supergfxctl](https://gitlab.com/asus-linux/supergfxctl) (running under OpenRC, of course)
