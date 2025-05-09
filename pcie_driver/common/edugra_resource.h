#ifndef _EDUGRA_COMMON_EDUGRA_RESOURCE_H_
#define _EDUGRA_COMMON_EDUGRA_RESOURCE_H_

#include "edugra_ioctl_common.h"
#include <linux/io.h>
#include <linux/types.h>

struct edugra_resource {
    uintptr_t   address;
    size_t      size;
};

#endif /* _EDUGRA_COMMON_EDUGRA_RESOURCE_H_ */