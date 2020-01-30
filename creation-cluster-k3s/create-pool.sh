#!/bin/bash
pool="k3s-pool"
pool_path="/var/lib/libvirt/multipass_images"
devname="vde"

virsh detach-disk --live $dom $devname
for node in node{1..3}; do virsh vol-delete volnode$i $pool;done
virsh pool-destroy $pool
virsh pool-undefine $pool

virsh pool-define-as $pool --type=dir "--target=$pool_path"
virsh pool build $pool
virsh pool-start $pool
virsh pool-autostart $pool
virsh pool-info $pool
for node in node{1..3}; do virsh vol-create-as --pool=$pool --name=vol$node --capacity=8GB --format=qcow2 ; done
for node in node{1..3}; 
do
    virsh attach-device --live $node /dev/stdin << EOF
       <disk type='file' device='disk'>
       <driver name='qemu' type='qcow2'/>
       <source file='$pool_path/vol$node'/>
       <target dev='vdc' bus='virtio'/>
       </disk>
EOF
done
