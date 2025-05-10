/*
EduGraphics_pcie_driver
*/

#ifndef _EDUGRA_PCI_FOPS_H_
#define _EDUGRA_PCI_FOPS_H_

#include "pcie.h"

int edugra_pcie_fops_open(struct inode* inode, struct file* filp);
ssize_t edugra_pcie_fops_read(struct file *filp, char __user *buf, size_t len, loff_t *offset);
int edugra_pcie_mmap(struct file *filp, struct vm_area_struct *vma);
ssize_t edugra_pcie_fops_write(struct file *filp, const char __user *buf, size_t len, loff_t *offset);
loff_t edugra_pcie_llseek(struct file *file, loff_t offset, int whence) ;
//int edugra_pcie_fops_release(struct inode* inode, struct file* filp);

#endif /* _EDUGRA_PCI_FOPS_H_ */