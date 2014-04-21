#!/bin/sh -x

pdsh -w ^lab-ips -f 80 '
mount | grep  sda1 ||  mount /dev/sda1 /mnt
mount | grep sda1 | awk '\''{system ("sed -i -e \"s/default=.*/default=0/\""  " " $3"/grub/grub.conf" )}'\'' 
/sbin/reboot
'
