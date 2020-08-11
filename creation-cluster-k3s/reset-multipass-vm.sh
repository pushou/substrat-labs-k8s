#!/bin/bash
MULTIPASS_STATE=$(multipass list)
LONGUEUR=${#MULTIPASS_STATE}

if [ $LONGUEUR != "19" ] ;
then
   echo "destruction via multipass"
   multipass list
   multipass stop --all
   multipass delete --all
   multipass purge
   exit 0
fi
MULTIPASS_STATE=$(multipass list)
LONGUEUR=${#MULTIPASS_STATE}
if [ $LONGUEUR != "19" ] ;
then
   echo "destruction via virsh"
   virsh list --all
   virsh destroy node1 node2 node3 master
   virsh undefine node1 node2 node3 master --remove-all-storage 
   echo "en dernier lieu faire sudo systemctl restart snap.multipass.multipassd.service"
fi

