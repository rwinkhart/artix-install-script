#!/usr/bin/env bash

loadkeys us
echo ----------------------------------------------------------------------------------------------
echo rwinkhart\'s artix install script
echo last updated september 20, 2022
echo ----------------------------------------------------------------------------------------------
echo You will be asked some questions before installation.
echo -e "----------------------------------------------------------------------------------------------\n"
read -n 1 -s -r -p 'Press any key to continue'

# start questions
echo Special Devices:
echo -e '\nspecial devices:\n1. asus rog zephyrus g14 2020 (not yet supported)\ngeneric:\n2. laptop\n3. desktop\n4. server\n'
read -n 1 -r -p "formfactor: " formfactor

fdisk -l
read -rp "disk: " disk

read -rp "swap (in GB): " swap

read -n 1 -rp "clean install? (y/N) " wipe
echo
read -rp "username: " username

read -rp "$username password: " userpassword

read -rp "root password: " rootpassword

read -rp "hostname: " hostname

echo -e '\namerica:'&&ls /usr/share/zoneinfo/America
echo -e 'e.g. "New_York" or "Aruba"\n'
read -r -p "timezone: " timezone
# stop questions

# start hardware detection
cpu=$(lscpu | grep 'Vendor ID:' | awk 'FNR == 1 {print $3;}')
threadsminusone=$(echo "$(lscpu | grep 'CPU(s):' | awk 'FNR == 1 {print $2;}') - 1" | bc)
gpu=$(lspci | grep 'VGA compatible controller:' | awk 'FNR == 1 {print $5;}')
ram=$(echo "$(< /proc/meminfo)" | grep 'MemTotal:' | awk '{print $2;}'); ram=$(echo "$ram / 1000000" | bc)
# stop hardware detection

# start conditional questions
if [ "$gpu" == 'Intel' ]; then
    echo -e '1. libva-intel-driver (intel igpus up to coffee lake)\n2. intel-media-driver (intel igpus/dgpus newer than coffee lake)\n'
    read -n 1 -rp "va-api driver: " intel_vaapi_driver
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

if [ "$formfactor" == 1 ]; then
    device='g14-'
else
    device=''
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
    mkdir -p /mnt/{boot/EFI,etc/conf.d}
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
    mkdir -p /mnt/etc/conf.d
fi

# create and mount swap file
if [ "$swap" != 0 ]; then
    dd if=/dev/zero of=/mnt/swapfile bs=1G count="$swap" status=progress
    chmod 600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
    echo 'vm.swappiness=10' > /mnt/etc/sysctl.d/99-swappiness.conf
else
    echo 'vm.swappiness=0' > /mnt/etc/sysctl.d/99-swappiness.conf
fi

fstabgen -U /mnt >> /mnt/etc/fstab
echo -e "\ntmpfs   /tmp         tmpfs   rw,nodev,nosuid,size="$(echo ".75 * $ram / 1" | bc)"G          0  0" >> /mnt/etc/fstab
# stop partitioning

# setting hostname
echo "$hostname" > /mnt/etc/hostname
echo "hostname=\'"$hostname"\'" > /mnt/etc/conf.d/hostname

# installing base packages
base_devel='db diffutils gc guile libisl libmpc perl autoconf automake binutils bison esysusers etmpfiles fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf python sed opendoas texinfo which'
basestrap /mnt base $base_devel openrc elogind-openrc linux linux-firmware git micro man-db

# exporting variables
mkdir /mnt/tempfiles
echo "$formfactor" > /mnt/tempfiles/formfactor
echo "$device" > /mnt/tempfiles/device
echo "$cpu" > /mnt/tempfiles/cpu
echo "$threadsminusone" > /mnt/tempfiles/threadsminusone
echo "$gpu" > /mnt/tempfiles/gpu
echo "$intel_vaapi_driver" > /mnt/tempfiles/intel_vaapi_driver
echo "$boot" > /mnt/tempfiles/boot
echo "$disk0" > /mnt/tempfiles/disk
echo "$username" > /mnt/tempfiles/username
echo "$userpassword" > /mnt/tempfiles/userpassword
echo "$rootpassword" > /mnt/tempfiles/rootpassword
echo "$timezone" > /mnt/tempfiles/timezone

# download and initiate part 2
curl https://raw.githubusercontent.com/rwinkhart/artix-install-script/main/chrootInstall.sh -o /mnt/chrootInstall.sh
chmod +x /mnt/chrootInstall.sh
artix-chroot /mnt /chrootInstall.sh
