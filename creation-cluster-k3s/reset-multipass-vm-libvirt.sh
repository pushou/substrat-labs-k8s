#!/bin/bash
echo "nettoyage musclé"
scriptname &>-
virsh list --all 
virsh destroy node1 node2 node3 master 
virsh undefine node1 node2 node3 master --remove-all-storage 
sudo pkill -9 -f qemu-system 
sudo systemctl restart snap.multipass.multipassd.service
