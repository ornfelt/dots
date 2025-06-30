#!/usr/bin/env bash

sudo umount /media
sudo umount /media2

# To check file system type before mounting:
# sudo blkid /dev/sda1
# sudo blkid /dev/sdb1
# Look for TYPE="exfat" or TYPE="ntfs" in the output.

# install this for exfat:
#sudo pacman -S exfatprogs fuse-exfat

#sudo mount -t ntfs-3g /dev/sdb1 /media -o uid=$(id -u $USER),gid=$(id -g $USER),umask=000
#sudo mount -t ntfs-3g /dev/sda1 /media2 -o uid=$(id -u $USER),gid=$(id -g $USER),umask=000

# exfat:
sudo mount -t exfat -o uid=$(id -u $USER),gid=$(id -g $USER),umask=000 /dev/sdb1 /media
sudo mount -t exfat -o uid=$(id -u $USER),gid=$(id -g $USER),umask=000 /dev/sda1 /media2

# For Seagate Expansion hdd (ntfs):
# sudo blkid /dev/sda1                                                                  [12:08:03]
# /dev/sda1: LABEL="Seagate Expansion Drive" BLOCK_SIZE="512" UUID="08BCEB86BCEB6D1E" TYPE="ntfs" PARTUUID="4f3f1114-01"
# Do this instead:
#sudo mount -t ntfs -o uid=$(id -u),gid=$(id -g),umask=000 /dev/sda1 /media2

