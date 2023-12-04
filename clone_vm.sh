#!/bin/bash

# Prompt the user for the name of the virtual machine to be cloned
echo -n "Enter the name of the virtual machine to be cloned: "

# List all VMs with their status
echo "Listing Virtual Machines with their states:"
virsh list --all --name | while read -r vm_name; do
    if [ -z "$vm_name" ]; then continue; fi  # Skip empty lines
    vm_state=$(virsh domstate "$vm_name")
    echo "$vm_name - $vm_state"
done

# Loop for VM selection
while true; do
    echo "Enter the name of the VM you want to select:"
    read vm

    # Check if the VM exists
    if virsh dominfo "${vm}" > /dev/null 2>&1; then
        vm_state=$(virsh domstate "$vm_name")
        if [[ "$vm_state" == "running" ]]; then
            echo "The VM $vm_name is running. A VM cannot be cloned while it is operational. Please shut it down first."
            exit 1
        else
            echo "You have selected the VM: ${vm}"
            break
        fi
    else
        echo "VM not found. Please enter a valid name."
    fi
done

# Prompt the user for the new name for the cloned virtual machine
echo -n "Enter the new name for the cloned virtual machine: "
read nnvm

while true; do
    echo "Please choose the cloning method for the VM volume:"
    echo "1. Full copy (independent clone)"
    echo "2. Linked clone (using a backing file)"
    echo "3. Help (explain options)"
    read -p "Enter your choice (1, 2, or 3): " cloning_method

    case $cloning_method in
        1)
            echo "You have chosen a full copy. This option will create an independent clone of the VM volume, which is a complete and standalone copy."
            break
            ;;
        2)
            echo "You have chosen a linked clone. This option will create a clone linked to the original volume using a backing file, which stores only the changes made to the original."
            break
            ;;
        3)
            echo "Help:"
            echo "- Full copy (Option 1): Creates a complete and independent copy of the VM volume. It's separate from the original and does not rely on it."
            echo "- Linked clone (Option 2): Creates a new VM volume linked to the original. Changes are stored separately, but the original volume is needed for the clone to function."
            ;;
        *)
            echo "Invalid input. Please enter 1, 2, or 3."
            ;;
    esac
done


echo "[${vm}] to be cloned as [${nnvm}]"

#get XML information
temp_dump=$(mktemp)
virsh dumpxml "${vm}" > "${temp_dump}" 2>/dev/null

# obtain volumes
disks=$(xmllint --xpath "//domain/devices/disk[@device='disk']/source/@file" "${temp_dump}" 2>/dev/null  | sed 's/^[[:space:]]*file="\([^"]*\)"/\1\n/g')
### sed 's/file="\([^"]*\)"/\1\n/g')

for disk in "${disks}"; do
        # obtain data of disk
        disk_format=$(qemu-img info "${disk}" | grep "file format" | awk '{ print $3 }')
        #obtain new path for cloned disk
        new_volume_path=$(echo "$disk" | sed "s/$vm/$nnvm/g")
        # get parent folder for disk and new volume
        disk_dirname=$(dirname "${disk}")
        new_volume_dir=$(dirname "${new_volume_path}")
        # create folder and maintain the user and group from the original disk parent folder
        mkdir -p "${new_volume_dir}"
        chown $(stat -c "%U:%G" "${disk_dirname}") "${new_volume_dir}"

        # clone disk depending on option
        if [[ "${cloning_method}" == "2" ]]; then
                qemu-img create -f "${disk_format}" -F "${disk_format}" -o backing_file="${disk}" "${new_volume_path}"
        else
                #rsync to display %
                rsync -ah --progress "${disk}" "${new_volume_path}"
        fi
done

#clone nvram if present
nvram_path=$(xmllint --xpath "string(//domain/os/nvram)" "${temp_dump}" 2>/dev/null)

if [[ -n "${nvram_path}" ]]; then
    new_nvram_path="/var/lib/libvirt/qemu/nvram/${nnvm}_VARS.fd"
    echo "Cloning NVRAM from ${nvram_path} to ${new_nvram_path}"
    cp "${nvram_path}" "${new_nvram_path}"
    sed -i "s#${nvram_path}#${new_nvram_path}#g" "${temp_dump}"
else
    echo "No NVRAM file found for the original VM, skipping NVRAM cloning."
fi



# delete current mac address
sed -i '/<mac address=/d' "${temp_dump}"
# remove uuid, this forces the creation of a new uuid
sed -i '/<uuid/d' "${temp_dump}"
# replace current name for new name on the dumpxml for virsh
sed -i "s#${vm}#${nnvm}#g" "${temp_dump}"


# clone server configuration
# modify configuration of the XML at temp_dump for ...

virsh define "${temp_dump}"
sleep 1
virsh start "${nnvm}"
