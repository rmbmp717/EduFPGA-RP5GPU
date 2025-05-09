/*
EduGraphics_pcie_driver
*/

#ifndef _COMMON_LOGS_H_
#define _COMMON_LOGS_H_

#include <linux/kern_levels.h>

// Should be used only by "module_param".
// Specify the current debug level for the logs
extern int o_dbg;


// Logging, same interface as dev_*, uses o_dbg to filter
// log messages
#define edugra_printk(level, dev, fmt, ...)              \
    do {                                                \
        int __level = (level[1] - '0');                 \
        if (__level <= o_dbg) {    \
            dev_printk((level), dev, fmt, ##__VA_ARGS__); \
        }                                               \
    } while (0)

#define edugra_emerg(board, fmt, ...) edugra_printk(KERN_EMERG, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_alert(board, fmt, ...) edugra_printk(KERN_ALERT, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_crit(board, fmt, ...)  edugra_printk(KERN_CRIT, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_err(board, fmt, ...) edugra_printk(KERN_ERR, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_warn(board, fmt, ...) edugra_printk(KERN_WARNING, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_notice(board, fmt, ...) edugra_printk(KERN_NOTICE, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_info(board, fmt, ...) edugra_printk(KERN_INFO, &(board)->pDev->dev, fmt, ##__VA_ARGS__)
#define edugra_dbg(board, fmt, ...) edugra_printk(KERN_DEBUG, &(board)->pDev->dev, fmt, ##__VA_ARGS__)

#define edugra_dev_emerg(dev, fmt, ...) edugra_printk(KERN_EMERG, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_alert(dev, fmt, ...) edugra_printk(KERN_ALERT, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_crit(dev, fmt, ...)  edugra_printk(KERN_CRIT, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_err(dev, fmt, ...) edugra_printk(KERN_ERR, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_warn(dev, fmt, ...) edugra_printk(KERN_WARNING, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_notice(dev, fmt, ...) edugra_printk(KERN_NOTICE, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_info(dev, fmt, ...) edugra_printk(KERN_INFO, dev, fmt, ##__VA_ARGS__)
#define edugra_dev_dbg(dev, fmt, ...) edugra_printk(KERN_DEBUG, dev, fmt, ##__VA_ARGS__)


#endif //_COMMON_LOGS_H_