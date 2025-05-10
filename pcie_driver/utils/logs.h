/*
EduGPU_pcie_driver
*/

#ifndef _COMMON_LOGS_H_
#define _COMMON_LOGS_H_

#include <linux/kern_levels.h>

// Should be used only by "module_param".
// Specify the current debug level for the logs
extern int o_dbg;


// Logging, same interface as dev_*, uses o_dbg to filter
// log messages
#define edugpu_printk(level, dev, fmt, ...)              \
    do {                                                \
        int __level = (level[1] - '0');                 \
        if (__level <= o_dbg) {    \
            dev_printk((level), dev, fmt, ##__VA_ARGS__); \
        }                                               \
    } while (0)

#define edugpu_emerg(board, fmt, ...) edugpu_printk(KERN_EMERG, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_alert(board, fmt, ...) edugpu_printk(KERN_ALERT, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_crit(board, fmt, ...)  edugpu_printk(KERN_CRIT, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_err(board, fmt, ...) edugpu_printk(KERN_ERR, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_warn(board, fmt, ...) edugpu_printk(KERN_WARNING, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_notice(board, fmt, ...) edugpu_printk(KERN_NOTICE, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_info(board, fmt, ...) edugpu_printk(KERN_INFO, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugpu_dbg(board, fmt, ...) edugpu_printk(KERN_DEBUG, &(board)->pDev->dev, fmt, ##__VA_ARGS__)

#define edugpu_dev_emerg(dev, fmt, ...) edugpu_printk(KERN_EMERG, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_alert(dev, fmt, ...) edugpu_printk(KERN_ALERT, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_crit(dev, fmt, ...)  edugpu_printk(KERN_CRIT, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_err(dev, fmt, ...) edugpu_printk(KERN_ERR, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_warn(dev, fmt, ...) edugpu_printk(KERN_WARNING, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_notice(dev, fmt, ...) edugpu_printk(KERN_NOTICE, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_info(dev, fmt, ...) edugpu_printk(KERN_INFO, dev, fmt, ##__VA_ARGS__)
#define edugpu_dev_dbg(dev, fmt, ...) edugpu_printk(KERN_DEBUG, dev, fmt, ##__VA_ARGS__)


#endif //_COMMON_LOGS_H_