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
