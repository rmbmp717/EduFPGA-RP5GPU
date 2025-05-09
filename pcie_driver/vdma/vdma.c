
/*
EduGraphics_pcie_driver
*/

#define pr_fmt(fmt) "edugra: " fmt

#include "vdma.h"
//#include "memory.h"
//#include "ioctl.h"
#include "utils/logs.h"

#include <linux/sched.h>
#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 10, 0)
#include <linux/dma-map-ops.h>
#else
#include <linux/dma-mapping.h>
#endif


static struct edugra_vdma_engine* init_vdma_engines(struct device *dev,
    struct edugra_resource *channel_registers_per_engine, size_t engines_count, u32 src_channels_bitmask)
{
    struct edugra_vdma_engine *engines = NULL;
    u8 i = 0;

    engines = devm_kmalloc_array(dev, engines_count, sizeof(*engines), GFP_KERNEL);
    if (NULL == engines) {
        dev_err(dev, "Failed allocating vdma engines\n");
        return ERR_PTR(-ENOMEM);
    }

    for (i = 0; i < engines_count; i++) {
        edugra_vdma_engine_init(&engines[i], i, &channel_registers_per_engine[i], src_channels_bitmask);
    }

    return engines;
}


int edugra_vdma_controller_init(struct edugra_vdma_controller *controller,
    struct device *dev, struct edugra_vdma_hw *vdma_hw,
    struct edugra_vdma_controller_ops *ops,
    struct edugra_resource *channel_registers_per_engine, size_t engines_count)
{
    int err = 0;
    controller->hw = vdma_hw;
    controller->ops = ops;
    controller->dev = dev;

    controller->vdma_engines_count = engines_count;
    controller->vdma_engines = init_vdma_engines(dev, channel_registers_per_engine, engines_count,
        vdma_hw->src_channels_bitmask);
    if (IS_ERR(controller->vdma_engines)) {
        dev_err(dev, "Failed initialized vdma engines\n");
        return PTR_ERR(controller->vdma_engines);
    }

    controller->used_by_filp = NULL;
    spin_lock_init(&controller->interrupts_lock);
    init_waitqueue_head(&controller->interrupts_wq);

    /* Check and configure DMA length */
    //err = edugra_set_dma_mask(dev);
    if (0 > err) {
        return err;
    }

    if (get_dma_ops(controller->dev)) {
        edugra_dev_notice(controller->dev, "Probing: Using specialized dma_ops=%ps", get_dma_ops(controller->dev));
    }

    return 0;
}