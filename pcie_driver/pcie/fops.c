/*
EduGraphics_pcie_driver
*/

#include <linux/version.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/pagemap.h>
#include <linux/uaccess.h>
#include <linux/scatterlist.h>
#include <linux/slab.h>
#include <linux/delay.h>

#include <asm/thread_info.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 11, 0)
#include <linux/sched/signal.h>
#endif

#include "fops.h"

// edugra_pcie_fops_openの実装
int edugra_pcie_fops_open(struct inode *inode, struct file *filp)
{
    printk("EduGra fp open\n");

    int err = 0;

    u32 major = MAJOR(inode->i_rdev);
    u32 minor = MINOR(inode->i_rdev);
    struct edugra_pcie_board *pBoard;

    pr_debug(DRIVER_NAME ": (%d: %d-%d): fops_open\n", current->tgid, major, minor);

    // allow multiple processes to open a device, count references in edugra_pcie_get_board_index.
    if (!(pBoard = edugra_pcie_get_board_index(minor))) {
        pr_err(DRIVER_NAME ": fops_open: PCIe board not found for /dev/hailoEduGraphics_pcie_driver%d node.\n", minor);
        err = -ENODEV;
    }

    // ファイルのプライベートデータにボード情報を保存
    filp->private_data = pBoard;
    pr_info(DRIVER_NAME ": Device opened successfully\n");

    return err;
}

// edugra_pcie_fops_readの実装
ssize_t edugra_pcie_fops_read(struct file *filp, char __user *buf, size_t len, loff_t *offset)
{
    struct edugra_pcie_board *pBoard = filp->private_data;
    void __iomem *bar2_addr;
    size_t bar2_size;
    size_t read_size;
    int err;

    pr_info("EduGraphics_pcie_driver: Edugra read called\n");

    // pBoardのNULLチェック
    if (!pBoard) {
        pr_err("EduGraphics_pcie_driver: private_data is NULL\n");
        return -ENODEV;
    }

    // BAR 2 (メインリソース)のアドレスとサイズを取得
    bar2_addr = (void __iomem *)pBoard->pcie_resources.edugra_registers.address;
    bar2_size = pBoard->pcie_resources.edugra_registers.size;

    // BAR2のNULLチェック
    if (!bar2_addr) {
        pr_err("EduGraphics_pcie_driver: BAR2 address is NULL\n");
        return -EFAULT;
    }

    // オフセットがBARのサイズを超えていないかを確認
    if (*offset >= bar2_size) {
        return 0;  // EOF (End of File)
    }

    // 読み取るサイズを決定（lenとBARの範囲内）
    read_size = min(len, bar2_size - (size_t)*offset);

    // リードされたアドレスとサイズを表示
    pr_info("EduGraphics_pcie_driver: Reading from BAR2 at address: 0x%p, offset: 0x%llx, size: %zu bytes\n", 
            bar2_addr, *offset, read_size);
    
    // ユーザ空間にデータをコピー
    err = copy_to_user(buf, bar2_addr + *offset, read_size);
    if (err) {
        pr_err("Failed to copy data to user\n");
        return -EFAULT;
    }

    // オフセットを更新
    *offset += read_size;

    return read_size;  // 読み取ったバイト数を返す
}

ssize_t edugra_pcie_fops_write(struct file *filp, const char __user *buf, size_t len, loff_t *ppos)
{
    struct edugra_pcie_board *pBoard = filp->private_data;
    void __iomem *bar2_addr;
    size_t bar2_size;
    size_t write_size;
    loff_t offset;
    int err;

    // pBoardのNULLチェック
    if (!pBoard) {
        pr_err("EduGraphics_pcie_driver: private_data is NULL\n");
        return -ENODEV;
    }

    // BAR2のアドレスとサイズを取得
    bar2_addr = (void __iomem *)pBoard->pcie_resources.edugra_registers.address;
    bar2_size = pBoard->pcie_resources.edugra_registers.size;

    // BAR2のNULLチェック
    if (!bar2_addr) {
        pr_err("EduGraphics_pcie_driver: BAR2 address is NULL\n");
        return -EFAULT;
    }

    // オフセットを取得
    offset = filp->f_pos;

    // オフセットがBARのサイズを超えていないかを確認
    if (offset >= bar2_size) {
        return -EFBIG;  // ファイルサイズ超過
    }

    // 書き込むサイズを決定（lenとBARの範囲内）
    write_size = min(len, (size_t)(bar2_size - offset));

    // 書き込まれるアドレスとサイズを表示
    pr_info("EduGraphics_pcie_driver: Writing to BAR2 at address: 0x%p, offset: 0x%llx, size: %zu bytes\n",
            bar2_addr, offset, write_size);

    // ポインタ演算のためにキャスト
    uint8_t __iomem *write_addr = (uint8_t __iomem *)bar2_addr + offset;

    // ユーザ空間からデータをコピー
    err = copy_from_user(write_addr, buf, write_size);
    if (err) {
        pr_err("Failed to copy data from user\n");
        return -EFAULT;
    }

    // ファイルポインタを更新
    filp->f_pos += write_size;

    pr_info("EduGraphics_pcie_driver: Write operation successful\n");

    return write_size;  // 書き込んだバイト数を返す
}


int edugra_pcie_mmap(struct file *filp, struct vm_area_struct *vma)
{
    struct edugra_pcie_board *pBoard = filp->private_data;
    size_t size = vma->vm_end - vma->vm_start;
    unsigned long pfn;
    size_t resource_size;

    // リソースサイズの取得
    resource_size = pBoard->pcie_resources.edugra_registers.size;

    // サイズのチェック
    if (size > resource_size) {
        pr_err("Requested mmap size is too large\n");
        return -EINVAL;
    }

    // ページフレーム番号（PFN）の取得
    pfn = (pBoard->pcie_resources.edugra_registers.address) >> PAGE_SHIFT;

    // メモリ領域をユーザ空間にマップ
    if (remap_pfn_range(vma, vma->vm_start, pfn, size, vma->vm_page_prot)) {
        pr_err("Failed to mmap device memory\n");
        return -EAGAIN;
    }

    return 0;
}


loff_t edugra_pcie_llseek(struct file *file, loff_t offset, int whence) {
    loff_t new_pos = 0;
    struct edugra_pcie_board *pBoard = file->private_data;
    size_t bar2_size = pBoard->pcie_resources.edugra_registers.size;

    switch (whence) {
        case SEEK_SET:
            new_pos = offset;
            break;
        case SEEK_CUR:
            new_pos = file->f_pos + offset;
            break;
        case SEEK_END:
            new_pos = bar2_size + offset;
            break;
        default:
            return -EINVAL;
    }

    if (new_pos < 0 || new_pos >= bar2_size) {
        return -EINVAL;
    }

    file->f_pos = new_pos;
    return new_pos;
}
