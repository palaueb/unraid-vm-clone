# unraid-vm-clone
more upgraded information at forum post: https://forums.unraid.net/topic/100225-vm-clonecopyduplicate/#comment-1334572

How to use

Connect to Unraid terminal.

Download clone_vm.sh file
```
wget https://github.com/palaueb/unraid-vm-clone/blob/main/clone_vm.sh
```

Check the file signature

```
$shasum clone_vm.sh
2193dcd662ac362c1cd49054ceed440f43a4fc69  clone_vm.sh
```

Change file permisions

```
chmod +x clone_vm.sh
```

Stop VM that you want to clone, then execute script

```
root@Tower:~# ./clone_vm.sh 
Enter the name of the virtual machine to be cloned: Listing Virtual Machines with their states:
k8s-node-master - shut off
Enter the name of the VM you want to select:
k8s-node-master
You have selected the VM: k8s-node-master
Enter the new name for the cloned virtual machine: k8s-node-cloned
Please choose the cloning method for the VM volume:
1. Full copy (independent clone)
2. Linked clone (using a backing file)
3. Help (explain options)
Enter your choice (1, 2, or 3): 1
You have chosen a full copy. This option will create an independent clone of the VM volume, which is a complete and standalone copy.
[k8s-node-master] to be cloned as [k8s-node-cloned]
sending incremental file list
vdisk1.img
          7.99G 100%  185.48MB/s    0:00:41 (xfr#1, to-chk=0/1)
Cloning NVRAM from /etc/libvirt/qemu/nvram/wwwwwwww-xxxx-yyyy-zzzz-d7a89d8a5218_VARS-pure-efi.fd to /var/lib/libvirt/qemu/nvram/k8s-node-cloned_VARS.fd
Domain 'k8s-node-cloned' defined from /tmp/tmp.ysKuBvXUae

Domain 'k8s-node-cloned' started
```

Now you have a duplicate, enter to the duplicated server and update hostname and network configuration if needed.
```
# for example on systemD
hostnamectl set-hostname my-cloned-server
```

The MAC address is regenerated, the UUID is regenerated. 

I hope it is useful and helpful to you
Please give feedback. 
