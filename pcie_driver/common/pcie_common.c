/*
EduGPU_pcie_driver
*/

#include "pcie_common.h"

#include <linux/errno.h>
#include <linux/bug.h>
#include <linux/delay.h>
#include <linux/kernel.h>
#include <linux/printk.h>
#include <linux/device.h>

#define BSC_IMASK_HOST (0x0188)

#define BCS_ISTATUS_HOST_VDMA_SRC_IRQ_MASK   (0x000000FF)
#define BCS_ISTATUS_HOST_VDMA_DEST_IRQ_MASK  (0x0000FF00)


u32 edugpu_resource_read32(struct edugpu_resource *resource, size_t offset)
{
    return ioread32((u8*)resource->address + offset);
}


void edugpu_resource_write32(struct edugpu_resource *resource, size_t offset, u32 value)
{
    iowrite32(value, (u8*)resource->address + offset);
}


void edugpu_pcie_update_channel_interrupts_mask(struct edugpu_pcie_resources* resources, u32 channels_bitmap)
{
    size_t i = 0;
    u32 mask = edugpu_resource_read32(&resources->config, BSC_IMASK_HOST);

    // Clear old channel interrupts
    mask &= ~BCS_ISTATUS_HOST_VDMA_SRC_IRQ_MASK;
    mask &= ~BCS_ISTATUS_HOST_VDMA_DEST_IRQ_MASK;
    // Set interrupt by the bitmap
    for (i = 0; i < MAX_VDMA_CHANNELS_PER_ENGINE; ++i) {
        if (edugpu_test_bit(i, &channels_bitmap)) {
            // based on 18.5.2 "vDMA Interrupt Registers" in PLDA documentation
            u32 offset = (i & 16) ? 8 : 0;
            edugpu_set_bit((((int)i*8) / MAX_VDMA_CHANNELS_PER_ENGINE) + offset, &mask);
        }
    }
    edugpu_resource_write32(&resources->config, BSC_IMASK_HOST, mask);
}

// On PCIe, just return the start address
u64 edugpu_pcie_encode_desc_dma_address_range(dma_addr_t dma_address_start, dma_addr_t dma_address_end, u32 step, u8 channel_id)
{
    (void)channel_id;
    (void)dma_address_end;
    (void)step;
    return (u64)dma_address_start;
}


struct edugpu_vdma_hw edugpu_pcie_vdma_hw = {
    .hw_ops = {
        .encode_desc_dma_address_range = edugpu_pcie_encode_desc_dma_address_range,
    },
    .ddr_data_id                = EDUGPU_PCIE_HOST_DMA_DATA_ID,
    .device_interrupts_bitmask  = EDUGPU_PCIE_DMA_DEVICE_INTERRUPTS_BITMASK,
    .host_interrupts_bitmask    = EDUGPU_PCIE_DMA_HOST_INTERRUPTS_BITMASK,
    .src_channels_bitmask       = EDUGPU_PCIE_DMA_SRC_CHANNELS_BITMASK,
};
