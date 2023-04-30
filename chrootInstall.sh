#!/usr/bin/env bash

# Importing Variables
formfactor="$(< /tempfiles/formfactor)"
cpu="$(< /tempfiles/cpu)"
threadsminusone="$(< /tempfiles/threadsminusone)"
gpu="$(< /tempfiles/gpu)"
intel_vaapi_driver="$(< /tempfiles/intel_vaapi_driver)"
boot="$(< /tempfiles/boot)"
disk="$(< /tempfiles/disk)"
username="$(< /tempfiles/username)"
userpassword="$(< /tempfiles/userpassword)"
rootpassword="$(< /tempfiles/rootpassword)"
timezone="$(< /tempfiles/timezone)"
swap="$(< /tempfiles/swap)"

# configuring locale and clock Settings
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
ln -s /usr/share/zoneinfo/America/"$timezone" /etc/localtime
locale-gen
hwclock --systohc --utc

# networkmanager configuration 
pacman -S networkmanager-openrc --noconfirm
rc-update add NetworkManager

# bootloader installation and configuration
pacman -S grub efibootmgr os-prober mtools dosfstools --noconfirm
if [ "$boot" == 1 ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB --recheck
fi
if [ "$boot" == 2 ]; then
    grub-install --target=i386-pc "$disk"
fi
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/grub -o /etc/default/grub
if [ "$gpu" == 'NVIDIA' ]; then
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nowatchdog retbleed=off mem_sleep_default=deep nohz_full=1-"$threadsminusone" nvidia-drm.modeset=1\"" >> /etc/default/grub
elif [ "$gpu" == 'AMD' ]; then
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nowatchdog retbleed=off mem_sleep_default=deep nohz_full=1-"$threadsminusone" amdgpu.ppfeaturemask=0xffffffff\"" >> /etc/default/grub
else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nowatchdog retbleed=off mem_sleep_default=deep nohz_full=1-"$threadsminusone"\"" >> /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

# account setup
groupadd classmod
echo "$rootpassword
$rootpassword
" | passwd
useradd -m -g users -G classmod "$username"
echo "$userpassword
$userpassword
" | passwd "$username"

# opendoas configuration
echo "permit persist keepenv $username as root
permit nopass $username as root cmd /usr/local/bin/powerset.sh
permit nopass $username as root cmd /usr/bin/poweroff
permit nopass $username as root cmd /usr/bin/reboot
" > /etc/doas.conf
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/doas-completion -o /usr/share/bash-completion/completions/doas
ln -s /usr/bin/doas /usr/bin/sudo

# pacman configuration
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/pacman.conf -o /etc/pacman.conf
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/makepkg.conf -o /etc/makepkg.conf
mkdir -p /etc/pacman.d/hooks
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/paccache-clean.hook -o /etc/pacman.d/hooks/paccache-clean.hook
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/modemmanager.hook -o /etc/pacman.d/hooks/modemmanager.hook
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/dash-link.hook -o /etc/pacman.d/hooks/dash-link.hook
if [ "$gpu" == 'NVIDIA' ]; then
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/nvidia.hook -o /etc/pacman.d/hooks/nvidia.hook
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/nvidia-lts.hook -o /etc/pacman.d/hooks/nvidia-lts.hook
fi

# shell configuration
mkdir /home/"$username"/.local/share/zsh
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/shell-profile -o /home/"$username"/.profile
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/bashrc -o /home/"$username"/.bashrc
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/zshrc -o /home/"$username"/.zshrc
chown "$username":users /home/"$username"/{.profile,.bashrc,.zshrc} /home/"$username"/.local/share/zsh
chsh -s /bin/dash "$username"
ln -sfT dash /usr/bin/sh
pacman -Sy zsh zsh-autosuggestions zsh-syntax-highlighting openrc-zsh-completions --noconfirm

# installing hardware-specific packages
if [ "$cpu" == 'AuthenticAMD' ]; then
    pacman -S amd-ucode --noconfirm
else
    pacman -S intel-ucode --noconfirm
fi
if [ "$gpu" == 'AMD' ]; then
    pacman -S mesa vulkan-icd-loader vulkan-radeon libva-mesa-driver libva-utils --needed --noconfirm
elif [ "$gpu" == 'Intel' ]; then
    pacman -S mesa vulkan-icd-loader vulkan-intel --needed --noconfirm
    if [ "$intel_vaapi_driver" == 1 ]; then
        pacman -S libva-intel-driver libva-utils --needed --noconfirm
    fi
    if [ "$intel_vaapi_driver" == 2 ]; then
        pacman -S intel-media-driver libva-utils --needed --noconfirm
    fi
elif [ "$gpu" == 'NVIDIA' ]; then
    pacman -S nvidia nvidia-utils nvidia-settings vulkan-icd-loader --needed --noconfirm
    echo 'options nvidia "NVreg_DynamicPowerManagement=0x02"' > /etc/modprobe.d/nvidia.conf
    echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/zz-nvidia-modeset.conf
fi

# disable kernel watchdog
echo 'blacklist iTCO_wdt' > /etc/modprobe.d/blacklist.conf

if [ "$formfactor" == 2 ] || [ "$formfactor" == 1 ]; then
    pacman -S powertop acpid-openrc acpilight --needed --noconfirm
    rc-update add acpid
    echo 'SUBSYSTEM=="backlight", ACTION=="add", \
        RUN+="/bin/chgrp classmod /sys/class/backlight/%k/brightness", \
        RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ' > /etc/udev/rules.d/screenbacklight.rules
fi

# set home directory permissions
mkdir -p /home/"$username"/{.config,.local/share}
chmod 700 /home/"$username"
chown "$username":users /home/"$username"/{.config,.local}
chown "$username":users /home/"$username"/.local/share
chmod 755 /home/"$username"/{.config,.local/share}

## KDE Plasma
if [ "$formfactor" == 1 ] || [ "$formfactor" == 2 ] || [ "$formfactor" == 3 ]; then
    pacman -S plasma-desktop plasma-wayland-session plasma-wayland-protocols kscreen kwallet-pam kdeplasma-addons spectacle gwenview plasma-nm plasma-pa breeze-gtk kde-gtk-config kio-extras khotkeys kwalletmanager yakuake ark kate bluedevil dolphin qt5-imageformats pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber wayland-protocols polkit micro bluez-openrc --needed --noconfirm
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/pam-login -o /etc/pam.d/login
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/konsole-profile -o /home/"$username"/.local/share/konsole/Custom.profile
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/konsolerc -o /home/"$username"/.config/konsolerc
    chmod 755 /home/"$username"/.config/konsolerc
    chown "$username":users /home/"$username"/.config/konsolerc
fi

mkdir /home/"$username"/.config/autostart
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/pipewire-start/pipewire.desktop -o /home/"$username"/.config/autostart/pipewire.desktop
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/powerset/powerset.sh -o /usr/local/bin/powerset.sh
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/pipewire-start/pipewire-start.sh -o /usr/local/bin/pipewire-start.sh
echo -e \#\!/usr/bin/env bash"\nfstrim -Av &" > /etc/local.d/trim.start
chmod 755 /usr/local/bin/powerset.sh /usr/local/bin/pipewire-start.sh /etc/local.d/trim.start
chown -R root /usr/local/bin /etc/local.d

# asus g14 2020 configuration
if [ "$formfactor" == 1 ]; then
    echo 'options snd_hda_intel power_save=1' > /etc/modprobe.d/audio_powersave.conf
    echo 'vm.dirty_writeback_centisecs = 6000' > /etc/sysctl.d/dirty.conf
    echo 'RUN+="/bin/chgrp classmod /sys/class/leds/asus::kbd_backlight/brightness"
    RUN+="/bin/chmod g+w /sys/class/leds/asus::kbd_backlight/brightness"
    ' > /etc/udev/rules.d/asuskbdbacklight.rules
    echo 'evdev:input:b0003v0B05p1866*
      KEYBOARD_KEY_c00b6=home # Fn+F2
      KEYBOARD_KEY_c00b5=end   # Fn+F4
      KEYBOARD_KEY_ff31007c=f20 # x11 mic-mute' > /etc/udev/hwdb.d/90-zephyrus-kbd.hwdb
    udevadm control --reload-rules
    udevadm trigger --sysname-match="event*"
    # xbindkeys config
    echo '#ScreenBrightUp
    "xbacklight -inc 10"
        m:0x0 + c:210
        XF86Launch3
    #ScreenBrightDown
    "xbacklight -dec 10"
        m:0x0 + c:157
        XF86Launch2
    #G14KeyBrightUp
    "xbacklight -ctrl asus::kbd_backlight -inc 30"
        m:0x0 + c:238
        XF86KbdBrightnessUp
    #G14KeyBrightDown
    "xbacklight -ctrl asus::kbd_backlight -dec 30"
        m:0x0 + c:237
        XF86KbdBrightnessDown
    #G14IntegratedGPU
    "/usr/bin/NVIDIA-FCKR integrated"
        m:0x0 + c:232
        XF86MonBrightnessDown
    #G14HybridGPU
    "/usr/bin/NVIDIA-FCKR hybrid"
        m:0x0 + c:233
        XF86MonBrightnessUp' > /home/"$username"/.xbindkeysrc
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/bashpower-g14/bashpower.start -o /etc/local.d/bashpower.start
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/NVIDIA-FCKR/NVIDIA-FCKR -o /usr/local/bin/NVIDIA-FCKR
    pacman -S mesa vulkan-icd-loader vulkan-radeon libva-mesa-driver libva-utils acpi_call --needed --noconfirm
    chmod 755 /etc/local.d/bashpower.start /usr/local/bin/NVIDIA-FCKR
fi

# ssh configuration
pacman -S openssh --needed --noconfirm
mkdir /home/"$username"/.ssh
touch /home/"$username"/.ssh/authorized_keys
chown -R "$username" /home/"$username"/.ssh
chmod 600 /home/"$username"/.ssh/authorized_keys

# misc configuration
if [ "$swap" -gt 0 ]; then
    echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
else
    echo 'vm.swappiness=0' > /etc/sysctl.d/99-swappiness.conf
fi
echo -e ""$username"        soft    memlock        64\n"$username"        hard    memlock        2097152\n"$username"        hard    nofile        524288\n# End of file" > /etc/security/limits.conf  # increase memlock and add support for esync
mkdir -p /home/"$username"/.gnupg
echo 'pinentry-program /usr/bin/pinentry-tty' > /home/"$username"/.gnupg/gpg-agent.conf  # forces gpg prompts to use terminal input
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/gai.conf -o /etc/gai.conf  # configure gai to prefer IPv6
echo 'vm.max_map_count=2147483642' > /etc/sysctl.d/90-override.conf  # increase max virtual memory maps (helps with some Wine games)
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/micro-settings.json -o /home/"$username"/.config/micro/settings.json  # set micro to use spaces in place of tabs
pacman -S neofetch htop --needed --noconfirm
rc-update add local default

# finishing up + cleaning
rm -rf /chrootInstall.sh /tempfiles
echo -e "\n---------------------------------------------------------"
echo installation completed!
echo please poweroff and remove the installation media before powering back on.
echo -e "---------------------------------------------------------\n"
exit
