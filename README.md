# Overview
An Artix Linux installation script that can be used to install and configure Artix Linux with my preferred setup.

Some major/noteworthy differences from common configurations:

- opendoas is used in place of sudo
- pipewire is used in place of pulseaudio
- EXT4 fast_commit mode is enabled by default
- makepkg is configured with better compression algorithms than the defaults and is forced to use all cores

# Usage
Upon loading up the official Artic base ISO, logging in, switching to the root user, and connecting to the internet, run:

```
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

After running the script, it will ask you some questions about your desired configuration. Answer them and then the installation will complete automatically.

# Supported Devices
Generic:

- Most x86_64 desktops, laptops, and servers
