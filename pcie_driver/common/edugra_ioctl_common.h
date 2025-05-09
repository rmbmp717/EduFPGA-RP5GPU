#ifndef _EDUGRA_IOCTL_COMMON_H_
#define _EDUGRA_IOCTL_COMMON_H_

#include <linux/limits.h>

#define CHANNEL_IRQ_TIMESTAMPS_SIZE (128 * 2)
#define CHANNEL_IRQ_TIMESTAMPS_SIZE_MASK (CHANNEL_IRQ_TIMESTAMPS_SIZE - 1)

#define HAILO_VDMA_MAX_ONGOING_TRANSFERS (128)
#define HAILO_VDMA_MAX_ONGOING_TRANSFERS_MASK (HAILO_VDMA_MAX_ONGOING_TRANSFERS - 1)

#define MAX_VDMA_CHANNELS_PER_ENGINE            (32)
#define HAILO_MAX_BUFFERS_PER_SINGLE_TRANSFER (2)

enum edugra_board_type {
    HAILO_BOARD_TYPE_HAILO8 = 0,
    HAILO_BOARD_TYPE_HAILO15,
    HAILO_BOARD_TYPE_PLUTO,
    HAILO_BOARD_TYPE_HAILO10H,
    HAILO_BOARD_TYPE_HAILO10H_LEGACY,
    HAILO_BOARD_TYPE_COUNT,

    /** Max enum value to maintain ABI Integrity */
    HAILO_BOARD_TYPE_MAX_ENUM = INT_MAX
};


enum edugra_accelerator_type {
    HAILO_ACCELERATOR_TYPE_NNC,
    HAILO_ACCELERATOR_TYPE_SOC,

    /** Max enum value to maintain ABI Integrity */
    HAILO_ACCELERATOR_TYPE_MAX_ENUM = INT_MAX
};


struct edugra_channel_interrupt_timestamp {
    uint64_t timestamp_ns;
    uint16_t desc_num_processed;
};

/* structure used in ioctl EDUGRA_VDMA_INTERRUPTS_READ_TIMESTAMPS */
struct edugra_vdma_interrupts_read_timestamp_params {
    uint8_t engine_index;                                                               // in
    uint8_t channel_index;                                                              // in
    uint32_t timestamps_count;                                                          // out
    struct edugra_channel_interrupt_timestamp timestamps[CHANNEL_IRQ_TIMESTAMPS_SIZE];   // out
};


#endif /* _EDUGRA_IOCTL_COMMON_H_ */