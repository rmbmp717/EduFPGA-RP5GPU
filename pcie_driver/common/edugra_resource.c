/*
EduGraphics_pcie_driver
*/

#include "edugra_resource.h"

#include <linux/io.h>
#include <linux/errno.h>
#include <linux/types.h>
#include <linux/kernel.h>

u8 edugra_resource_read8(struct edugra_resource *resource, size_t offset)
{
    return ioread8((u8*)resource->address + offset);
}