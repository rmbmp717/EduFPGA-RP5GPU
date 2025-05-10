/*
EduGPU_pcie_driver
*/

#ifndef _EDUGPU_VDMA_VDMA_H_
#define _EDUGPU_VDMA_VDMA_H_

#include "edugpu_ioctl_common.h"
#include "edugpu_resource.h"
#include "vdma_common.h"

#include <linux/dma-mapping.h>
#include <linux/types.h>
#include <linux/semaphore.h>
#include <linux/dma-buf.h>
#include <linux/version.h>


struct edugpu_vdma_controller;
struct edugpu_vdma_controller_ops {
    void (*update_channel_interrupts)(struct edugpu_vdma_controller *controller, size_t engine_index,
        u32 channels_bitmap);
};


struct edugpu_vdma_controller {
    struct edugpu_vdma_hw *hw;
    struct edugpu_vdma_controller_ops *ops;
    struct device *dev;

    size_t vdma_engines_count;
    struct edugpu_vdma_engine *vdma_engines;

    spinlock_t interrupts_lock;
    wait_queue_head_t interrupts_wq;

    struct file *used_by_filp;

    // Putting big IOCTL structures here to avoid stack allocation.
    struct edugpu_vdma_interrupts_read_timestamp_params read_interrupt_timestamps_params;
};


int edugpu_vdma_controller_init(struct edugpu_vdma_controller *controller,
    struct device *dev, struct edugpu_vdma_hw *vdma_hw,
    struct edugpu_vdma_controller_ops *ops,
    struct edugpu_resource *channel_registers_per_engine, size_t engines_count);

#endif /* _EDUGPU_VDMA_VDMA_H_ */