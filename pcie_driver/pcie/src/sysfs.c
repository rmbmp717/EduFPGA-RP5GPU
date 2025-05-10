/*
EduGPU_pcie_driver
*/

#include "sysfs.h"
#include "pcie.h"

#include <linux/device.h>
#include <linux/sysfs.h>

static ssize_t accelerator_type_show(struct device *dev, struct device_attribute *_attr,
    char *buf)
{
    struct edugpu_pcie_board *board = (struct edugpu_pcie_board *)dev_get_drvdata(dev);
    return sprintf(buf, "%d", board->pcie_resources.accelerator_type);
}
static DEVICE_ATTR_RO(accelerator_type);

static struct attribute *edugpu_dev_attrs[] = {
    &dev_attr_accelerator_type.attr,
    NULL
};

ATTRIBUTE_GROUPS(edugpu_dev);
const struct attribute_group **g_edugpu_dev_groups = edugpu_dev_groups;