#!/bin/bash

vgchange -ay

pvcreate $1
vgcreate dockerdata $1
lvcreate --name volume1 -l 100%FREE dockerdata
mkfs.ext4 /dev/dockerdata/volume1

mkdir -p /var/lib/docker

echo '/dev/dockerdata/volume1 /var/lib/docker ext4 defaults 0 0' >> /etc/fstab
mount /var/lib/docker
