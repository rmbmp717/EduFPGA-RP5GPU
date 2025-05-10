/*
EduGPU_pcie_driver
*/

#include "edugpu_resource.h"

#include <linux/io.h>
#include <linux/errno.h>
#include <linux/types.h>
#include <linux/kernel.h>

u8 edugpu_resource_read8(struct edugpu_resource *resource, size_t offset)
{
    return ioread8((u8*)resource->address + offset);
}