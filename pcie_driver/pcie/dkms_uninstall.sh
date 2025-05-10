#!/bin/bash
set -e
DRIVER_NAME_NO_EXT="EduGraphics_pcie_driver"
DRIVER_NAME="EduGraphics_pcie_driver.ko.xz"

rm -rf /var/lib/dkms/$DRIVER_NAME_NO_EXT/*
rm -rf /lib/modules/*/updates/dkms/$DRIVER_NAME
rm -rf /usr/src/$DRIVER_NAME_NO_EXT-*
