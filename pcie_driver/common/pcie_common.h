/*
EduGPU_pcie_driver
*/
#ifndef _EDUGPU_COMMON_PCIE_COMMON_H_
#define _EDUGPU_COMMON_PCIE_COMMON_H_

#include "edugpu_resource.h"
#include "utils.h"
#include "vdma_common.h"
#include "edugpu_ioctl_common.h"

#include <linux/types.h>
#include <linux/firmware.h>

#define DRIVER_NAME		"EduGPU_pcie_driver"

#define PCI_VENDOR_ID_EDUGPU                0x22C2
#define PCI_DEVICE_ID_EDUGPU        	    0x1100

extern struct edugpu_vdma_hw edugpu_pcie_vdma_hw;

#define EDUGPU_PCIE_CONFIG_BAR       (0)
#define EDUGPU_PCIE_REGS_BAR         (2)
#define EDUGPU_PCIE_FW_ACCESS_BAR    (4)

#define EDUGPU_PCIE_HOST_DMA_DATA_ID (0)
#define EDUGPU_PCIE_DMA_DEVICE_INTERRUPTS_BITMASK    (1 << 4)
#define EDUGPU_PCIE_DMA_HOST_INTERRUPTS_BITMASK      (1 << 5)
#define EDUGPU_PCIE_DMA_SRC_CHANNELS_BITMASK         (0x0000FFFF)

struct edugpu_pcie_resources {
    struct edugpu_resource config;               // BAR0
    struct edugpu_resource edugpu_registers;       // BAR2
    struct edugpu_resource fw_access;            // BAR4
    enum edugpu_board_type board_type;
    enum edugpu_accelerator_type accelerator_type;
};

void edugpu_pcie_update_channel_interrupts_mask(struct edugpu_pcie_resources *resources, u32 channels_bitmap);

u32 edugpu_resource_read32(struct edugpu_resource *resource, size_t offset);

void edugpu_resource_write32(struct edugpu_resource *resource, size_t offset, u32 value);

u64 edugpu_pcie_encode_desc_dma_address_range(dma_addr_t dma_address_start,
                                              dma_addr_t dma_address_end,
                                              u32 step,
                                              u8 channel_id);

#endif /* _EDUGPU_COMMON_PCIE_COMMON_H_ */
