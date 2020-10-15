#!/usr/bin/env bash
################################################################################
# Filename: diskSectorCalculator.sh
# Date Created: 21-dec-19
# Date last update: 21-dec-19
# Author: Marco Tijbout
#
# Version 0.1
#
# Usage: This script is called from the ArchInstallation.sh script.
#        This script can be used stand-alone.
#
# Enhancement ideas:
#
# Version history:
# 0.1  Marco Tijbout:
#   Initial release of the script.
################################################################################

DISK_SIZE=$DISK_SIZE_GB #GB
SWAP_SIZE=2
GB_MB=1024

BOOT_SIZE_MB=512
DISK_SIZE_MB=$(( $DISK_SIZE * $GB_MB))
SWAP_SIZE_MB=$(( $SWAP_SIZE * $GB_MB))
DISK_BLOCKS=$(( ($DISK_SIZE_MB * 1024 * 1024) / 512))

# Disk details:
echo -e "\nDisk size in GB: $DISK_SIZE"
echo -e "Disk size in MB: $DISK_SIZE_MB"
echo -e "Disk size in blocks: $DISK_BLOCKS"

# Boot partition:
echo -e "\nboot partition: $BOOT_SIZE_MB MB"
BOOT_BLOCKS=$(( ($BOOT_SIZE_MB * 1024 * 1024) / 512))
echo -e "boot partition: $BOOT_BLOCKS blocks"

# Swap partition:
echo -e "\nswap partition: $SWAP_SIZE GB"
SWAP_BLOCKS=$(( ($SWAP_SIZE_MB * 1024 * 1024) / 512))
echo -e "swap partition: $SWAP_BLOCKS blocks"

# Root partition:
ROOT_SIZE_MB=$(( $DISK_SIZE_MB - $BOOT_SIZE_MB - $SWAP_SIZE_MB ))
ROOT_SIZE=$(( $ROOT_SIZE_MB / $GB_MB))
echo -e "\nroot partition: $ROOT_SIZE GB"
ROOT_BLOCKS=$(( ($ROOT_SIZE_MB * 1024 * 1024) / 512))
echo -e "root partition: $ROOT_BLOCKS blocks"

# Disk sector layout:
BOOT_START=2048
ROOT_START=$(($BOOT_START + $BOOT_BLOCKS ))
SWAP_START=$(( $ROOT_START + $ROOT_BLOCKS))

echo -e "\nBoot start: $BOOT_START"
echo -e "Root start: $ROOT_START"
echo -e "Swap start: $SWAP_START"

MAX_DISK_SECTORS=$(( $DISK_BLOCKS -34 ))
SWAP_BLOCKS_CORRECTION=$(( $SWAP_BLOCKS - 2082))

# Create sfdisk partition layout file:
cat <<EOL > layout.sfdisk
label: gpt
device: /dev/sda
unit: sectors
first-lba: $BOOT_START
last-lba: $MAX_DISK_SECTORS

/dev/sda1 : start=        $BOOT_START, size=     $BOOT_BLOCKS, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
/dev/sda2 : start=     $ROOT_START, size=    $ROOT_BLOCKS, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
/dev/sda3 : start=    $SWAP_START, size=     $SWAP_BLOCKS_CORRECTION, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
EOL

echo -e "\nDisplay layout.sfdisk file:\n"

cat layout.sfdisk
