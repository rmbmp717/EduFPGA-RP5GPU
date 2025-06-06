#ifndef _EDUGPU_PCI_PCIE_H_
#define _EDUGPU_PCI_PCIE_H_

#include "vdma/vdma.h"
#include "pcie_common.h"

#include <linux/pci.h>
#include <linux/fs.h>
#include <linux/interrupt.h>
#include <linux/circ_buf.h>
#include <linux/device.h>

#include <linux/ioctl.h>

#define NISHIHARU_DRV_VER "0.8.5"

struct edugpu_pcie_board {
    struct list_head board_list;
    struct pci_dev *pDev;
    u32 board_index;
    atomic_t ref_count;
    struct list_head open_files_list;
    struct edugpu_pcie_resources pcie_resources;
    struct edugpu_vdma_controller vdma;
};


struct edugpu_pcie_board* edugpu_pcie_get_board_index(u32 index);

#endif /* _EDUGPU_PCI_PCIE_H_ */
