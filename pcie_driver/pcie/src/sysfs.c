/*
EduGraphics_pcie_driver
*/

#include "sysfs.h"
#include "pcie.h"

#include <linux/device.h>
#include <linux/sysfs.h>

static ssize_t accelerator_type_show(struct device *dev, struct device_attribute *_attr,
    char *buf)
{
    struct edugra_pcie_board *board = (struct edugra_pcie_board *)dev_get_drvdata(dev);
    return sprintf(buf, "%d", board->pcie_resources.accelerator_type);
}
static DEVICE_ATTR_RO(accelerator_type);

static struct attribute *edugra_dev_attrs[] = {
    &dev_attr_accelerator_type.attr,
    NULL
};

ATTRIBUTE_GROUPS(edugra_dev);
const struct attribute_group **g_edugra_dev_groups = edugra_dev_groups;