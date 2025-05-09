/*
EduGraphics_pcie_driver
*/

#include "vdma_common.h"

#include <linux/types.h>
#include <linux/errno.h>
#include <linux/bug.h>
#include <linux/circ_buf.h>
#include <linux/ktime.h>
#include <linux/timekeeping.h>
#include <linux/kernel.h>
#include <linux/kconfig.h>
#include <linux/printk.h>


#define CHANNEL_BASE_OFFSET(channel_index) ((channel_index) << 5)

#define CHANNEL_CONTROL_OFFSET      (0x0)
#define CHANNEL_DEPTH_ID_OFFSET     (0x1)
#define CHANNEL_NUM_AVAIL_OFFSET    (0x2)
#define CHANNEL_NUM_PROC_OFFSET     (0x4)
#define CHANNEL_ERROR_OFFSET        (0x8)
#define CHANNEL_DEST_REGS_OFFSET    (0x10)


static u8 __iomem *get_channel_regs(u8 __iomem *regs_base, u8 channel_index, bool is_host_side, u32 src_channels_bitmask)
{
    // Check if getting host side regs or device side
    u8 __iomem *channel_regs_base = regs_base + CHANNEL_BASE_OFFSET(channel_index);
    if (is_host_side) {
        return edugra_test_bit(channel_index, &src_channels_bitmask) ? channel_regs_base :
            (channel_regs_base + CHANNEL_DEST_REGS_OFFSET);
    } else {
        return edugra_test_bit(channel_index, &src_channels_bitmask) ? (channel_regs_base + CHANNEL_DEST_REGS_OFFSET) :
            channel_regs_base;
    }
}


static void channel_state_init(struct edugra_vdma_channel_state *state)
{
    state->num_avail = state->num_proc = 0;

    // Special value used when the channel is not activate.
    state->desc_count_mask = U32_MAX;
}


void edugra_vdma_engine_init(struct edugra_vdma_engine *engine, u8 engine_index,
    const struct edugra_resource *channel_registers, u32 src_channels_bitmask)
{
    u8 channel_index = 0;
    struct edugra_vdma_channel *channel;

    engine->index = engine_index;
    engine->enabled_channels = 0x0;
    engine->interrupted_channels = 0x0;

    for_each_vdma_channel(engine, channel, channel_index) {
        u8 __iomem *regs_base = (u8 __iomem *)channel_registers->address;
        channel->host_regs = get_channel_regs(regs_base, channel_index, true, src_channels_bitmask);
        channel->device_regs = get_channel_regs(regs_base, channel_index, false, src_channels_bitmask);
        channel->index = channel_index;
        channel->timestamp_measure_enabled = false;

        channel_state_init(&channel->state);
        channel->last_desc_list = NULL;

        channel->ongoing_transfers.head = 0;
        channel->ongoing_transfers.tail = 0;
    }
}

