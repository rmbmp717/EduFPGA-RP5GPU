#ifndef _EDUGPU_COMMON_EDUGPU_RESOURCE_H_
#define _EDUGPU_COMMON_EDUGPU_RESOURCE_H_

#include "edugpu_ioctl_common.h"
#include <linux/io.h>
#include <linux/types.h>

struct edugpu_resource {
    uintptr_t   address;
    size_t      size;
};

/* 関数プロトタイプを追記 */
u8 edugpu_resource_read8(struct edugpu_resource *resource, size_t offset);

#endif /* _EDUGPU_COMMON_EDUGPU_RESOURCE_H_ */
