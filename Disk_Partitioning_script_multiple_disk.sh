#!/bin/bash
#script is used to part and mount the multiple disk
# Define the disk letter range
DISK_RANGE=(e f g h i j k l m n o p q r s t u)  # Represents disks from /dev/sde to /dev/sdu
MOUNT_BASE="/data"  # Base mount point
MOUNT_START_NUMBER=4    # Starting number for mount directories (data4, data5, ...)

# Initialize a counter for disk mount naming
COUNTER=$MOUNT_START_NUMBER

# Loop through each disk in the range
for DISK_LETTER in "${DISK_RANGE[@]}"; do
    # Define the disk and mount point
    DISK="/dev/sd${DISK_LETTER}"
    MOUNT_POINT="${MOUNT_BASE}${COUNTER}"

    echo "Processing $DISK..."

    # Check if the disk exists before proceeding
    if [ ! -b "$DISK" ]; then
        echo "Error: Device $DISK not found. Skipping."
        continue
    fi

    # Unmount the disk if it's already mounted
    sudo umount ${DISK}* 2>/dev/null

    # Create a GPT partition table (for large disks over 2TB)
    sudo parted $DISK mklabel gpt

    # Create a primary partition spanning the entire disk
    sudo parted -a optimal $DISK mkpart primary ext4 0% 100%

    # Format the partition to ext4
    sudo mkfs.ext4 ${DISK}1

    # Create a unique mount point for each disk
    sudo mkdir -p $MOUNT_POINT

    # Mount the partition
    sudo mount ${DISK}1 $MOUNT_POINT

    # Set up fstab to auto-mount on boot
    UUID=$(sudo blkid -s UUID -o value ${DISK}1)
    echo "UUID=${UUID} $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab

    # Verify the disk is mounted
    df -h | grep $MOUNT_POINT

    echo "Disk ${DISK}1 formatted and mounted at ${MOUNT_POINT}"

    # Increment the counter for the next disk
    COUNTER=$((COUNTER + 1))
done

echo "All disks from /dev/sde to /dev/sdu have been processed."

