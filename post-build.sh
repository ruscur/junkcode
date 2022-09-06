#!/bin/bash

set -u
set -e

# Mount debugfs on boot
mkdir -p /sys/kernel/debug
if [[ ! $(grep debugfs /etc/fstab) ]]; then
    echo "debugfs     /sys/kernel/debug debugfs defaults 0 0" >> ${TARGET_DIR}/etc/fstab
fi

# Fix modprobe and friends being stupid
if [ ! -f ${TARGET_DIR}/bin/kmod ]; then
   ln -s /usr/bin/kmod ${TARGET_DIR}/bin/kmod
fi
