/*
EduGPU_pcie_driver
*/

#ifndef _EDUGPU_COMMON_VDMA_COMMON_H_
#define _EDUGPU_COMMON_VDMA_COMMON_H_

#include "edugpu_resource.h"
#include "utils.h"
#include "edugpu_ioctl_common.h"

#include <linux/types.h>
#include <linux/scatterlist.h>
#include <linux/io.h>

#define MAX_DIRTY_DESCRIPTORS_PER_TRANSFER      \
    (HAILO_MAX_BUFFERS_PER_SINGLE_TRANSFER + 1)

struct edugpu_ongoing_transfer {
    uint16_t last_desc;

    u8 buffers_count;
    //struct hailo_vdma_mapped_transfer_buffer buffers[HAILO_MAX_BUFFERS_PER_SINGLE_TRANSFER];

    // Contains all descriptors that were programmed with non-default values
    // for the transfer (by non-default we mean - different size or different
    // interrupts domain).
    uint8_t dirty_descs_count;
    uint16_t dirty_descs[MAX_DIRTY_DESCRIPTORS_PER_TRANSFER];

    // If set, validate descriptors status on transfer completion.
    bool is_debug;
};


struct edugpu_ongoing_transfers_list {
    unsigned long head;
    unsigned long tail;
    struct edugpu_ongoing_transfer transfers[HAILO_VDMA_MAX_ONGOING_TRANSFERS];
};


struct edugpu_vdma_hw_ops {
    // Accepts start, end and step of an address range (of type  dma_addr_t).
    // Returns the encoded base address or INVALID_VDMA_ADDRESS if the range/step is invalid.
    // All addresses in the range of [returned_addr, returned_addr + step, returned_addr + 2*step, ..., dma_address_end) are valid.
    u64 (*encode_desc_dma_address_range)(dma_addr_t dma_address_start, dma_addr_t dma_address_end, u32 step, u8 channel_id);
};


struct edugpu_vdma_hw {
    struct edugpu_vdma_hw_ops hw_ops;

    // The data_id code of ddr addresses.
    u8 ddr_data_id;

    // Bitmask needed to set on each descriptor to enable interrupts (either host/device).
    unsigned long host_interrupts_bitmask;
    unsigned long device_interrupts_bitmask;

    // Bitmask for each vdma hw, which channels are src side by index (on pcie/dram - 0x0000FFFF, pci ep - 0xFFFF0000)
    u32 src_channels_bitmask;
};


struct edugpu_vdma_channel_state {
    // vdma channel counters. num_avail should be synchronized with the hw
    // num_avail value. num_proc is the last num proc updated when the user
    // reads interrupts.
    u16 num_avail;
    u16 num_proc;

    // Mask of the num-avail/num-proc counters.
    u32 desc_count_mask;
};


struct edugpu_channel_interrupt_timestamp_list {
    int head;
    int tail;
    struct edugpu_channel_interrupt_timestamp timestamps[CHANNEL_IRQ_TIMESTAMPS_SIZE];
};


struct edugpu_vdma_channel {
    u8 index;

    u8 __iomem *host_regs;
    u8 __iomem *device_regs;

    // Last descriptors list attached to the channel. When it changes,
    // assumes that the channel got reset.
    struct edugpu_vdma_descriptors_list *last_desc_list;

    struct edugpu_vdma_channel_state state;
    struct edugpu_ongoing_transfers_list ongoing_transfers;

    bool timestamp_measure_enabled;
    struct edugpu_channel_interrupt_timestamp_list timestamp_list;
};

#define _for_each_element_array(array, size, element, index) \
    for (index = 0, element = &array[index]; index < size; index++, element = &array[index])


#define for_each_vdma_channel(engine, channel, channel_index) \
    _for_each_element_array((engine)->channels, MAX_VDMA_CHANNELS_PER_ENGINE,   \
        channel, channel_index)


struct edugpu_vdma_engine {
    u8 index;
    u32 enabled_channels;
    u32 interrupted_channels;
    struct edugpu_vdma_channel channels[MAX_VDMA_CHANNELS_PER_ENGINE];
};

void edugpu_vdma_engine_init(struct edugpu_vdma_engine *engine, u8 engine_index,
    const struct edugpu_resource *channel_registers, u32 src_channels_bitmask);


#endif /* _EDUGPU_COMMON_VDMA_COMMON_H_ */