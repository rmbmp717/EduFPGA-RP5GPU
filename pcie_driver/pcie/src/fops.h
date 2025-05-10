/*
EduGPU_pcie_driver
*/

#ifndef _EDUGPU_PCI_FOPS_H_
#define _EDUGPU_PCI_FOPS_H_

#include "pcie.h"

int edugpu_pcie_fops_open(struct inode* inode, struct file* filp);
ssize_t edugpu_pcie_fops_read(struct file *filp, char __user *buf, size_t len, loff_t *offset);
int edugpu_pcie_mmap(struct file *filp, struct vm_area_struct *vma);
ssize_t edugpu_pcie_fops_write(struct file *filp, const char __user *buf, size_t len, loff_t *offset);
loff_t edugpu_pcie_llseek(struct file *file, loff_t offset, int whence) ;
//int edugpu_pcie_fops_release(struct inode* inode, struct file* filp);

#endif /* _EDUGPU_PCI_FOPS_H_ */