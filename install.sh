#!/bin/bash
loadkeys us
echo ----------------------------------------------------------------------------------------------
echo rwinkhart\'s artix installer
echo last updated june 25, 2022
echo ----------------------------------------------------------------------------------------------
echo You will be asked some questions before installation.
echo -e "----------------------------------------------------------------------------------------------\n"
read -n 1 -s -r -p 'Press any key to continue'

# start questions
echo Special Devices:
echo -e '\nspecial devices:\n1. asus rog zephyrus g14 2020 (not yet supported)\ngeneric:\n2. laptop\n3. desktop\n4. server\n'
read -n 1 -r -p "formfactor: " formfactor

fdisk -l
read -r -p "disk: " disk

read -r -p "swap (in GB): " swap

read -n 1 -r -p "clean install? (y/N) " wipe

read -r -p "username: " username

read -r -p "$username password: " userpassword

read -r -p "root password: " rootpassword

read -r -p "hostname: " hostname
# stop questions

# start hardware detection
cpu=$(lscpu | grep 'Vendor ID:' | awk 'FNR == 1 {print $3;}')
gpu=$(lspci | grep 'VGA compatible controller:' | awk 'FNR == 1 {print $5;}')
# stop hardware detection

# start conditional questions
if [ "$gpu" == 'Intel' ]; then
    echo -e '1. libva-intel-driver (intel igpus up to coffee lake)\n2. intel-media-driver (intel igpus/dgpus newer than coffee lake)\n'
    read -n 1 -r -p "va-api driver: " intel_vaapi_driver
fi
# stop conditional questions

# start variable manipulation
wipe=$(echo "$wipe" | tr '[:upper:]' '[:lower:]')
username=$(echo "$username" | tr '[:upper:]' '[:lower:]')
hostname=$(echo "$hostname" | tr '[:upper:]' '[:lower:]')

disk0=$disk
if [[ "$disk" == /dev/nvme0n* ]]; then
    disk="$disk"'p'
fi
if [[ "$disk" == /dev/mmcblk* ]]; then
    disk="$disk"'p'
fi
# stop variable manipulation

# determine if running as UEFI or BIOS
if [ -d "/sys/firmware/efi" ]; then
    boot=1
else
    boot=2
fi

# start partitioning
if [ "$boot" == 1 ]; then
    # gpt/uefi partitioning
    if [ "$wipe" == y ]; then
        partitions=0
        echo "g
        n
        1

        +256M
        t
        1
        n



        w
        " | fdisk -w always -W always "$disk0"
    else
        partitions=$(lsblk "$disk0" -o NAME | grep -o '.$' | tail -1)
        echo "n


        +256M
        t

        1
        n



        w
        " | fdisk -W always "$disk0"
    fi

    # disk formatting
    mkfs.fat -F32 "$disk""$((1 + "$partitions"))"
    mkfs.ext4 -O fast_commit "$disk""$((2 + "$partitions"))"

    # mounting storage and efi partitions
    mount "$disk""$((2 + "$partitions"))" /mnt
    mkdir -p /mnt/{boot/EFI,etc}
    mount "$disk""$((1 + "$partitions"))" /mnt/boot/EFI
else
    # mbr/bios partitioning
    if [ "$wipe" == y ]; then
        partitions=0
        echo "o
        n
        p



        w
        " | fdisk -w always -W always "$disk0"
    else
        partitions=$(lsblk "$disk0" -o NAME | grep -o '.$' | tail -1)
        echo "n
        p



        w
        " | fdisk -W always "$disk0"
    fi

    # disk formatting
    mkfs.ext4 -O fast_commit "$disk""$((1 + "$partitions"))"

    # mounting storage (no efi partition, using dos label)
    mount "$disk""$((1 + "$partitions"))" /mnt
    mkdir /mnt/etc
fi

# create and mount swap file
if [ "$swap" != 0 ]; then
    dd if=/dev/zero of=/mnt/swapfile bs=1G count="$swap" status=progress
    chmod 600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
fi

fstabgen -U /mnt >> /mnt/etc/fstab
# stop partitioning

# setting hostname
echo "$hostname" > /mnt/etc/hostname

# installing base packages
base_devel='autoconf automake binutils bison fakeroot file findutils flex gawk gcc gettext grep groff pigz pbzip2 libtool m4 make pacman patch pkgconf sed opendoas texinfo which'
basestrap /mnt base $base_devel openrc elogind-openrc linux linux-firmware

# exporting variables
mkdir /mnt/tempfiles
echo "$formfactor" > /mnt/tempfiles/formfactor
echo "$cpu" > /mnt/tempfiles/cpu
echo "$gpu" > /mnt/tempfiles/gpu
echo "$intel_vaapi_driver" > /mnt/tempfiles/intel_vaapi_driver
echo "$boot" > /mnt/tempfiles/boot
echo "$disk0" > /mnt/tempfiles/disk
echo "$username" > /mnt/tempfiles/username
echo "$userpassword" > /mnt/tempfiles/userpassword
echo "$rootpassword" > /mnt/tempfiles/rootpassword

# download and initiate part 2
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/chrootInstall.sh -o /mnt/chrootInstall.sh
chmod +x /mnt/chrootInstall.sh
artix-chroot /mnt /chrootInstall.sh
