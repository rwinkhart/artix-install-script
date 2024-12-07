#!/usr/bin/env bash

loadkeys us
echo ----------------------------------------------------------------------------------------------
echo rwinkhart\'s Artix Install Script
echo Last updated December 06, 2024 \(rev. C\)
echo ----------------------------------------------------------------------------------------------
echo You will be asked some questions before installation.
echo -e "----------------------------------------------------------------------------------------------\n"
read -n 1 -s -r -p 'Press any key to continue'

# BEGIN BASIC QUESTIONS
echo -e '\nSpecial devices:\n1. ASUS Zephyrus G14 (2020)\nGeneric:\n2. Laptop\n3. Desktop\n4. Headless desktop\n'
read -n 1 -r -p "Formfactor: " formfactor

echo -e "\n"
fdisk -l
echo
read -rp "Disk: " disk

read -rp "Swap (in GB): " swap

read -n 1 -rp "Clean install? (y/N) " wipe
echo
read -rp "Username: " username

read -rp "$username password: " userpassword

read -rp "Hostname: " hostname
# END BASIC QUESTIONS

# BEGIN TIMEZONE CONFIGURATION
zroot=/usr/share/zoneinfo

show_tz_list() {
    echo

    local i z= list=
    local path="$zroot/$1"
    [ -d "$path" ] || return 1

    for i in $(find $path/ -maxdepth 1); do
        case $i in
        *.tab|*/) continue;;
        esac
        if [ -d "$i" ]; then
            z="$z ${i##*/}/"
        else
            z="$z ${i##*/}"
        fi
    done
    ( cd $path && ls --color=never -Cd $z )
}

while true; do
    show_tz_list
    echo
    read -rp "Timezone: " timezone
    case "$timezone" in
        none|abort) break;;
        "") continue;;
        "?") show_tz_list; continue;;
    esac

    while [ -d "$zroot/$timezone" ]; do
        show_tz_list "$timezone"
        echo
        read -rp "$timezone subset: " zone
        case "$zone" in
            "?") show_tz_list "$timezone"; continue;;
        esac
        timezone="$timezone/$zone"
    done

    if [ -f "$zroot/$timezone" ]; then
        timezone="$zroot/$timezone"
        break
    fi
    echo "'$timezone' is not a valid timezone on this system"
done
# END TIMEZONE CONFIGURATION

# BEGIN HARDWARE DETECTION
pacman -S bc --noconfirm
threadsminusone=$(echo "$(lscpu | grep 'CPU(s):' | awk 'FNR == 1 {print $2;}') - 1" | bc)

gpu=$(lspci | grep 'VGA compatible controller:' | awk 'FNR == 1 {print $5;}')
if ! ([ "$gpu" == 'NVIDIA' ] || [ "$gpu" == 'Intel' ]); then
    gpu=AMD
fi

ram=$(echo "$(< /proc/meminfo)" | grep 'MemTotal:' | awk '{print $2;}'); ram=$(echo "$ram / 1000000" | bc)

interfaces=(/sys/class/net/*)

res_detect=$(</sys/class/graphics/fb0/modes)
res_detect="${res_detect:2:${#res_detect}-5}"
res_x=$(printf "$res_detect" | cut -d 'x' -f1)
res_y_half=$(echo "$(echo "$res_detect" | cut -d 'x' -f2) / 2" | bc)
# END HARDWARE DETECTION

# BEGIN CONDITIONAL QUESTIONS
if [ "$gpu" == 'Intel' ]; then
    echo -e '1. libva-intel-driver (Intel iGPUs up to Coffee Lake)\n2. intel-media-driver (Intel iGPUs/dGPUs Broadwell and newer)\n'
    read -n 1 -rp "va-api driver: " intel_vaapi_driver
fi
# END CONDITIONAL QUESTIONS

# BEGIN VARIABLE MANIPULATION
wipe=$(echo "$wipe" | tr '[:upper:]' '[:lower:]')
username=$(echo "$username" | tr '[:upper:]' '[:lower:]')
hostname=$(echo "$hostname" | tr '[:upper:]' '[:lower:]')

disk0=$disk
if [[ "$disk" == /dev/nvme0n* ]] || [[ "$disk" == /dev/mmcblk* ]]; then
    disk="$disk"'p'
fi

if [ "$formfactor" == 1 ]; then
    gpu=NVIDIA
fi
# END VARIABLE MANIPULATION

# determine if running as UEFI or BIOS
if [ -d "/sys/firmware/efi" ]; then
    boot=1
else
    boot=2
fi

# BEGIN PARTITIONING
if [ "$boot" == 1 ]; then
    # gpt/uefi partitioning
    if [ "$wipe" == y ]; then
        partitions=0
        wipefs --all --force "$disk0"
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
if [ "$swap" -gt 0 ]; then
    dd if=/dev/zero of=/mnt/swapfile bs=1G count="$swap" status=progress
    chmod 600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
fi

fstabgen -U /mnt >> /mnt/etc/fstab
echo -e "\ntmpfs   /tmp         tmpfs   rw,nodev,nosuid,size="$(echo ".75 * $ram / 1" | bc)"G          0  0" >> /mnt/etc/fstab
# END PARTITIONING

# manually binding localhost
echo "127.0.0.1 localhost" > /mnt/etc/hosts

# setting hostname
echo "$hostname" > /mnt/etc/hostname
echo "hostname=\'"$hostname"\'" > /mnt/etc/conf.d/hostname

# installing base packages
base_devel='db diffutils gc guile libisl libmpc perl autoconf automake bash dash binutils bison esysusers etmpfiles fakeroot file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman pacman-contrib patch pkgconf sed opendoas texinfo which bc udev ntp'
basestrap /mnt base $base_devel openrc elogind-openrc linux linux-firmware git man-db iptables-nft

# applying IPv6 privacy extensions for all interfaces
echo -e 'net.ipv6.conf.all.use_tempaddr = 2\nnet.ipv6.conf.default.use_tempaddr = 2' > /mnt/etc/sysctl.d/40-ipv6.conf
for int in "${interfaces[@]}"; do
      echo "net.ipv6.conf.${int:15}.use_tempaddr = 2" >> /mnt/etc/sysctl.d/40-ipv6.conf
done

# setting basic restrictions on sysrq
echo 'kernel.sysrq = 244' > /mnt/etc/sysctl.d/35-sysrq.conf

# create array of variables to pass to part 2
var_export=($formfactor $threadsminusone $gpu $boot $disk0 $username $userpassword $timezone $swap $intel_vaapi_driver $res_x $res_y_half)

# initiate part 2
mount --bind /root/artix-install-script /mnt/mnt
artix-chroot /mnt /mnt/chrootInstall.sh "${var_export[@]}"
