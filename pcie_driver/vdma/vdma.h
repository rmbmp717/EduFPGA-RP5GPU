/*
EduGraphics_pcie_driver
*/

#ifndef _EDUGRA_VDMA_VDMA_H_
#define _EDUGRA_VDMA_VDMA_H_

#include "edugra_ioctl_common.h"
#include "edugra_resource.h"
#include "vdma_common.h"

#include <linux/dma-mapping.h>
#include <linux/types.h>
#include <linux/semaphore.h>
#include <linux/dma-buf.h>
#include <linux/version.h>


struct edugra_vdma_controller;
struct edugra_vdma_controller_ops {
    void (*update_channel_interrupts)(struct edugra_vdma_controller *controller, size_t engine_index,
        u32 channels_bitmap);
};


struct edugra_vdma_controller {
    struct edugra_vdma_hw *hw;
    struct edugra_vdma_controller_ops *ops;
    struct device *dev;

    size_t vdma_engines_count;
    struct edugra_vdma_engine *vdma_engines;

    spinlock_t interrupts_lock;
    wait_queue_head_t interrupts_wq;

    struct file *used_by_filp;

    // Putting big IOCTL structures here to avoid stack allocation.
    struct edugra_vdma_interrupts_read_timestamp_params read_interrupt_timestamps_params;
};


int edugra_vdma_controller_init(struct edugra_vdma_controller *controller,
    struct device *dev, struct edugra_vdma_hw *vdma_hw,
    struct edugra_vdma_controller_ops *ops,
    struct edugra_resource *channel_registers_per_engine, size_t engines_count);

#endif /* _EDUGRA_VDMA_VDMA_H_ */