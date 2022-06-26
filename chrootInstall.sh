#!/bin/bash

# Importing Variables
formfactor="$(cat /tempfiles/formfactor)"
cpu="$(cat /tempfiles/cpu)"
gpu="$(cat /tempfiles/gpu)"
intel_vaapi_driver="$(cat /tempfiles/intel_vaapi_driver)"
boot="$(cat /tempfiles/boot)"
disk="$(cat /tempfiles/disk)"
username="$(cat /tempfiles/username)"
userpassword="$(cat /tempfiles/userpassword)"
rootpassword="$(cat /tempfiles/rootpassword)"

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
    grub-install --target=x86_64-efi --bootloader-id=GRUB-rwinkhart --recheck
fi
if [ "$boot" == 2 ]; then
    grub-install --target=i386-pc "$disk"
fi
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
if [ "$gpu" != 'NVIDIA' ]; then
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/grub -o /etc/default/grub
else
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/grub-nvidia -o /etc/default/grub
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
echo "permit persist keepenv $username as root" > /etc/doas.conf
ln -s /usr/bin/doas /usr/bin/sudo

# misc. configuration
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/makepkg.conf -o /etc/makepkg.conf
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/bashrc -o /home/"$username"/.bashrc
chown "$username":"$users" /home/"$username"/.bashrc

# pacman configuration
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/paccache-clean-hook -o /etc/pacman.d/hooks/paccache-clean.hook
if [ "$gpu" == 'NVIDIA' ]; then
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/config-files/nvidia-hook -o /etc/pacman.d/hooks/nvidia.hook
fi

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

if [ "$formfactor" == 2 ]; then
    pacman -R xorg-xbacklight --noconfirm
    pacman -S powertop acpid-openrc acpilight --needed --noconfirm
    rc-update add acpid
    echo 'SUBSYSTEM=="backlight", ACTION=="add", \
        RUN+="/bin/chgrp classmod /sys/class/backlight/%k/brightness", \
        RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ' > /etc/udev/rules.d/screenbacklight.rules
fi

# setting home directory permissions
chmod -R 700 /home

# installing desktop environment and addons + utilities
if [ "$formfactor" -lt 4 ]; then
    pacman -S pipewire pipewire-pulse pipewire-jack pipewire-alsa libpulse plasma-desktop lightdm-openrc lightdm-gtk-greeter kscreen kdeplasma-addons spectacle gwenview plasma-nm plasma-pa breeze-gtk kde-gtk-config kio-extras khotkeys kwalletmanager pcmanfm-qt yakuake ark kate micro bluedevil bluez --needed --noconfirm
    rc-update add lightdm
    ln -s /usr/bin/micro /usr/bin/nano
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/xcaffeine/xcaffeine.py -o /usr/bin/xcaffeine.py
    chmod 755 /usr/bin/xcaffeine.py
    curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/programs/xcaffeine/xcaffeine.desktop -o /home/"$username"/.config/autostart/xcaffeine.desktop
    chmod 644 /home/"$username"/.config/autostart/xcaffeine.desktop
fi

# installing and configuring basic software packages
if [ "$formfactor" == 4 ]; then
    pacman -S openssh --needed --noconfirm
    mkdir /home/"$username"/.ssh
    touch /home/"$username"/.ssh/authorized_keys
    chmod 700 /home/"$username"/.ssh
    chmod 600 /home/"$username"/.ssh/authorized_keys
    chown -R "$username" /home/"$username"/.ssh
fi
echo -e '*        hard    memlock        64\n*        soft    memlock        2097152\n# End of file' > /etc/security/limits.conf  # increases hard memlock limit to 2 GiB (useful for some apps, such as rpcs3)
mkdir -p /home/"$username"/.gnupg
echo 'pinentry-program /usr/bin/pinentry-tty' > /home/"$username"/.gnupg/gpg-agent.conf  # forces gpg prompts to use terminal input
pacman -S neofetch htop cpupower --needed --noconfirm

# finishing up + cleaning
rm -rf /chrootInstall.sh /tempfiles
echo -e "\n---------------------------------------------------------"
echo installation completed!
echo please poweroff and remove the installation media before powering back on.
echo -e "---------------------------------------------------------\n"
exit
