#!/usr/bin/env bash
################################################################################
# Filename: ArchInstallation.sh
# Date Created: 21-dec-19
# Date last update: 21-dec-19
# Author: Marco Tijbout
#
# Version 0.1
#
# Enhancement ideas:
#   - 
#
# Update history:
# 20191224 Updated the sed command.
# 20191221 0.1 Marco Tijbout: Initial version of the script.
# 20201015 0.2 Robel Campbell: Taylored this script to suit my needs
################################################################################

################################################################################
## PRE-INSTALLATION
################################################################################

# Configure to use NTP (preferably already before the script is run):
echo -e "\n * Configure system to use NTP ...\n"
timedatectl set-ntp true

# Check if the installation disk of 40GB is found:
echo -e "\n * Probe the installation disk ...\n"
DISK_NAME=$(fdisk -l | grep "GiB" | awk -F ':' '{print $1}' | awk '{print $2}')
echo -e "Disk: Recognized as $DISK_NAME"

DISK_SIZE_GB=$(fdisk -l | grep "GiB" | awk '{print $3}')
echo -e "Disk: Size in GB: $DISK_SIZE_GB"

# Create a partition layout file for a 40GB disk:
echo -e "\n * Create partition layout file ...\n"
source diskSectorCalculator.sh $DISK_SIZE_GB

# Partition the disk based on the layout file:
echo -e "\n * Partition the disk ...\n"
sfdisk --force $DISK_NAME < layout.sfdisk

# Formatting the freshly created partitions:
echo -e "\n * Formatting the partitions on the disk ...\n"
mkfs.fat -F32 ${DISK_NAME}1
mkfs.ext4 -F ${DISK_NAME}2

# Prep and enable the swap partition:
echo -e "\n * Enable swap partition ...\n"
mkswap ${DISK_NAME}3
swapon ${DISK_NAME}3

# Mounting the partitions:
echo -e "\n * Mounting of the partitions ...\n"
mount ${DISK_NAME}2 /mnt
mkdir -p /mnt/boot
mount ${DISK_NAME}1 /mnt/boot

################################################################################
## INSTALLATION
################################################################################

# Configure the fastest nearest mirror:

# Backup:
echo -e "\n * Backup mirrorlist ...\n"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.org

# Add the mirror information to the top:
echo -e "\n * Add Netherlands miror to top of mirrorlist ...\n"
sed -i '6i## United States\' /etc/pacman.d/mirrorlist
sed -i '7iServer = http://mirrors.acm.wpi.edu/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist

# Install essential packages:
echo -e "\n * Install essential packages ...\n"
pacstrap /mnt base base-devel linux linux-firmware nano

# Create FSTAB file
echo -e "\n * Create fstab file ...\n"
genfstab -U /mnt >> /mnt/etc/fstab

################################################################################
## CHROOT - INSTALLATION
################################################################################

# Prepare installation steps during chroot:
echo -e "\n * Prep second stage in chroot ...\n"

# Create the file to be executed the chroot environment:
cat <<EOF > /mnt/root/ArchInstallation2.sh
#!/usr/bin/env bash
################################################################################
# Filename: ArchInstallation2.sh
# Date Created: 21-dec-19
# Date last update: 21-dec-19
# Author: Marco Tijbout
#
# Version 0.1
#
# Enhancement ideas:
#   - Using flags to specify values to arguments.
#   - Option to update the script (-u --update -au (allways update))
#
# Version history:
# 0.1  Marco Tijbout:
#   Initial release of the script.
################################################################################

################################################################################
## CHROOT - INSTALLATION
################################################################################
TARGET_MACHINE=archb3l

# Set the locale for the system:
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Generate the locales:
locale-gen

# Configure what language to use:
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set time zone to Europe Amsterdam:
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# Set the time standard to UTC using command:
hwclock --systohc --utc

# Set the hostname
echo "$TARGET_MACHINE" >> /etc/hostname

# Fill the hosts file:
cat <<EOI > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $TARGET_MACHINE.localdomain     $TARGET_MACHINE
EOI

# Install and enable netowrkmanager:
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Install and enable OpenSSH
pacman -S --noconfirm openssh
systemctl enable sshd

# Install the bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n * Set password for root Don't forget to change this!!!...\n"
echo -e "root\nroot" | passwd

# Exit this part of the script
exit
EOF

# Make second installation script executable:
echo -e "\n * Make second installation script executable ...\n"
chmod +x /mnt/root/ArchInstallation2.sh

# Switch to newly installed version and continue installation:
echo -e "\n * Chroot and continue installation ...\n"
arch-chroot /mnt /root/ArchInstallation2.sh

################################################################################
## END OF INSTALLATION
################################################################################

echo -e "\n * Back from chroot ...\n"

# Unmount the partitions:
echo -e "\n * Unmount the partitions ...\n"
umount -R /mnt

# End of the script:
echo -e "\n * Script is finished.\nReady to reboot into the new system ...\n"
