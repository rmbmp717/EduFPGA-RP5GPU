/*
EduGraphics_pcie_driver
*/
#ifndef _EDUGRA_COMMON_PCIE_COMMON_H_
#define _EDUGRA_COMMON_PCIE_COMMON_H_

#include "edugra_resource.h"
#include "utils.h"
#include "vdma_common.h"
#include "edugra_ioctl_common.h"

#include <linux/types.h>
#include <linux/firmware.h>

#define DRIVER_NAME		"EduGraphics_pcie_driver"

#define PCI_VENDOR_ID_EDUGRA              0x22C2
#define PCI_DEVICE_ID_EDUGRA        	    0x1100

extern struct edugra_vdma_hw edugra_pcie_vdma_hw;

#define EDUGRA_PCIE_CONFIG_BAR       (0)
#define EDUGRA_PCIE_REGS_BAR         (2)
#define EDUGRA_PCIE_FW_ACCESS_BAR    (4)

#define EDUGRA_PCIE_HOST_DMA_DATA_ID (0)
#define EDUGRA_PCIE_DMA_DEVICE_INTERRUPTS_BITMASK    (1 << 4)
#define EDUGRA_PCIE_DMA_HOST_INTERRUPTS_BITMASK      (1 << 5)
#define EDUGRA_PCIE_DMA_SRC_CHANNELS_BITMASK         (0x0000FFFF)

struct edugra_pcie_resources {
    struct edugra_resource config;               // BAR0
    struct edugra_resource edugra_registers;       // BAR2
    struct edugra_resource fw_access;            // BAR4
    enum edugra_board_type board_type;
    enum edugra_accelerator_type accelerator_type;
};

void edugra_pcie_update_channel_interrupts_mask(struct edugra_pcie_resources *resources, u32 channels_bitmap);

#endif /* _EDUGRA_COMMON_PCIE_COMMON_H_ */
