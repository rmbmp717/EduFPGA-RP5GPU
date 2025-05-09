/*
EduGraphics_pcie_driver
*/

#include <linux/version.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/pci_regs.h>
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/pagemap.h>
#include <linux/firmware.h>
#include <linux/kthread.h>

#include "utils/compact.h"
#include "utils/logs.h"
#include "vdma/vdma.h"

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 16, 0)
#include <linux/dma-direct.h>
#endif

#define KERNEL_CODE	1

#include "pcie.h"
#include "fops.h"
#include "sysfs.h"

static LIST_HEAD(g_edugra_board_list);
static struct semaphore g_edugra_add_board_mutex = __SEMAPHORE_INITIALIZER(g_edugra_add_board_mutex, 1);

static int char_major = 0;
static struct class *chardev_class;

// should be called only from fops_open (once)
struct edugra_pcie_board* edugra_pcie_get_board_index(u32 index)
{
    struct edugra_pcie_board *pBoard, *pRet = NULL;

    down(&g_edugra_add_board_mutex);
    list_for_each_entry(pBoard, &g_edugra_board_list, board_list)
    {
        if ( index == pBoard->board_index )
        {
            atomic_inc(&pBoard->ref_count);
            pRet = pBoard;
            break;
        }
    }
    up(&g_edugra_add_board_mutex);

    return pRet;
}

static void edugra_pcie_insert_board(struct edugra_pcie_board* pBoard)
{
    u32 index = 0;
    struct edugra_pcie_board *pCurrent, *pNext;


    down(&g_edugra_add_board_mutex);
    if ( list_empty(&g_edugra_board_list)  ||
            list_first_entry(&g_edugra_board_list, struct edugra_pcie_board, board_list)->board_index > 0)
    {
        pBoard->board_index = 0;
        list_add(&pBoard->board_list, &g_edugra_board_list);

        up(&g_edugra_add_board_mutex);
        return;
    }

    list_for_each_entry_safe(pCurrent, pNext, &g_edugra_board_list, board_list)
    {
        index = pCurrent->board_index+1;
        if( list_is_last(&pCurrent->board_list, &g_edugra_board_list) || (index != pNext->board_index))
        {
            break;
        }
    }
}

static int edugra_bar_iomap(struct pci_dev *pdev, int bar, struct edugra_resource *resource)
{
    resource->size = pci_resource_len(pdev, bar);
    resource->address = (uintptr_t)(pci_iomap(pdev, bar, resource->size));

    if (!resource->size || !resource->address) {
        //edugra_err(pdev, "Probing: Invalid PCIe BAR %d", bar);
        return -EINVAL;
    }

    pci_notice(pdev, "Probing: mapped bar %d - %p %zu\n", bar,
        (void*)resource->address, resource->size);
    return 0;
}


static void edugra_bar_iounmap(struct pci_dev *pdev, struct edugra_resource *resource)
{
    if (resource->address) {
        pci_iounmap(pdev, (void*)resource->address);
        resource->address = 0;
        resource->size = 0;
    }
}

static void pcie_resources_release(struct pci_dev *pdev, struct edugra_pcie_resources *resources)
{
    edugra_bar_iounmap(pdev, &resources->config);
    edugra_bar_iounmap(pdev, &resources->edugra_registers);
    edugra_bar_iounmap(pdev, &resources->fw_access);
    pci_release_regions(pdev);
}


static void update_channel_interrupts(struct edugra_vdma_controller *controller,
    size_t engine_index, u32 channels_bitmap)
{
    struct edugra_pcie_board *board = (struct edugra_pcie_board*) dev_get_drvdata(controller->dev);
    if (engine_index >= board->vdma.vdma_engines_count) {
        //edugra_err(board, "Invalid engine index %zu", engine_index);
        return;
    }

    edugra_pcie_update_channel_interrupts_mask(&board->pcie_resources, channels_bitmap);
}

static struct edugra_vdma_controller_ops pcie_vdma_controller_ops = {
    .update_channel_interrupts = update_channel_interrupts,
};


static int edugra_pcie_vdma_controller_init(struct edugra_vdma_controller *controller,
    struct device *dev, struct edugra_resource *vdma_registers)
{
    const size_t engines_count = 1;
    return edugra_vdma_controller_init(controller, dev, &edugra_pcie_vdma_hw,
        &pcie_vdma_controller_ops, vdma_registers, engines_count);
}



static int pcie_resources_init(struct pci_dev *pDev, struct edugra_pcie_resources *resources,
    enum edugra_board_type board_type)
{
    int err = -EINVAL;

    // Log message to indicate the function has been called
    dev_notice(&pDev->dev, "pcie_resources_init\n");

    // Request PCIe regions for the device
    err = pci_request_regions(pDev, DRIVER_NAME);
    if (err) {
        dev_err(&pDev->dev, "Failed to request PCI regions, err=%d\n", err);
        return err;  // Return error if regions cannot be requested
    }

    // BAR for config space access
    err = edugra_bar_iomap(pDev, EDUGRA_PCIE_CONFIG_BAR, &resources->config);
    if (err) {
        dev_err(&pDev->dev, "Failed to map config BAR, err=%d\n", err);
        return err; 
    }

    err = edugra_bar_iomap(pDev, EDUGRA_PCIE_REGS_BAR, &resources->edugra_registers);
    if (err) {
        dev_err(&pDev->dev, "Failed to map registers BAR, err=%d\n", err);
        return err; 
    }

    err = edugra_bar_iomap(pDev, EDUGRA_PCIE_FW_ACCESS_BAR, &resources->fw_access);
    if (err) {
        dev_err(&pDev->dev, "Failed to map firmware access BAR, err=%d\n", err);
        return err; 
    }

    // If all BARs are successfully mapped, return 0 to indicate success
    pci_notice(pDev, "pcie_resources_init Done\n");
    return 0;
}


// プローブ関数: デバイスが検出されたときに呼び出される
static int edugra_pcie_probe(struct pci_dev* pDev, const struct pci_device_id* id)
{
    struct edugra_pcie_board * pBoard;
    struct device *char_device = NULL;
    int err = -EINVAL;

    dev_notice(&pDev->dev, "Probing on: %04x:%04x...\n", pDev->vendor, pDev->device);

    /* Initialize device extension for the board*/
    pci_notice(pDev, "Probing: Allocate memory for device extension, %zu\n", sizeof(struct edugra_pcie_board));
    pBoard = (struct edugra_pcie_board*) kzalloc( sizeof(struct edugra_pcie_board), GFP_KERNEL);
    if (pBoard == NULL)
    {
        pci_err(pDev, "Probing: Failed to allocate memory for device extension structure\n");
        err = -ENOMEM;
    }

    pBoard->pDev = pDev;

    // ここにデバイス初期化処理を追加
    if ( (err = pci_enable_device(pDev)) )
    {
        pci_err(pDev, "Probing: Failed calling pci_enable_device %d\n", err);
    }
    pci_notice(pDev, "Probing: Device enabled\n");

    // DMA処理
    err = edugra_pcie_vdma_controller_init(&pBoard->vdma, &pBoard->pDev->dev, &pBoard->pcie_resources.edugra_registers);
    if (err < 0) {
        edugra_err(pBoard, "Failed init vdma controller %d\n", err);
        goto probe_release_pcie_resources;
    }

    // PCIマスターにセット
    pci_notice(pDev, "pci_set_master Init\n");
    pci_set_master(pDev);
    pci_notice(pDev, "pci_set_master Done\n");

    err = pcie_resources_init(pDev, &pBoard->pcie_resources, id->driver_data);
    if (err < 0) {
        pci_err(pDev, "Probing: Failed init pcie resources");
        goto probe_disable_device;
    }

    /* Keep track on the device, in order, to be able to remove it later */
    pci_set_drvdata(pDev, pBoard);
    edugra_pcie_insert_board(pBoard);

    // キャラクタデバイスの作成  
    char_device = device_create_with_groups(chardev_class, NULL,
                                            MKDEV(char_major, 0),
                                            NULL,
                                            g_edugra_dev_groups,
                                            "EduGraphics_pcie_driver%d", 0);

    return 0;

probe_release_pcie_resources:
    pcie_resources_release(pBoard->pDev, &pBoard->pcie_resources);

probe_disable_device:
    pci_disable_device(pDev);

    return err;

}


// リムーブ関数: デバイスが取り外されたときに呼び出される
static void edugra_pcie_remove(struct pci_dev* pDev)
{
    dev_notice(&pDev->dev, "Remove: Releasing board\n");
    // ここにデバイスのクリーンアップ処理を追加
    pci_disable_device(pDev);
}



// デバイスIDテーブル
static struct pci_device_id edugra_pcie_id_table[] =
{
    { PCI_DEVICE(PCI_VENDOR_ID_EDUGRA, PCI_DEVICE_ID_EDUGRA) },
    { 0 }
};

// 各種システムコールに対応するハンドラテーブル
static struct file_operations edugra_pcie_fops =
{
    owner:              THIS_MODULE,
    open:               edugra_pcie_fops_open,
    read:               edugra_pcie_fops_read,
    write:              edugra_pcie_fops_write,
    mmap:               edugra_pcie_mmap,
    llseek:             edugra_pcie_llseek, 
    //release:            edugra_pcie_fops_release
};

// PCIドライバ構造体
static struct pci_driver edugra_pci_driver =
{
    name:                DRIVER_NAME,
    id_table:            edugra_pcie_id_table,
    probe:               edugra_pcie_probe,
    remove:              edugra_pcie_remove,
};

static int edugra_pcie_register_chrdev(unsigned int major, const char *name)
{
    int char_major;

    char_major = register_chrdev(major, name, &edugra_pcie_fops);

    // キャラクタデバイスクラスの作成
    chardev_class = class_create_compat("EduGraphics_chardev");
    
    return char_major;
}

static void edugra_pcie_unregister_chrdev(unsigned int major, const char *name)
{
    class_destroy(chardev_class);
    unregister_chrdev(major, name);
}

// モジュールの初期化関数
static int __init edugra_pci_driver_init(void) {
    
    pr_notice(DRIVER_NAME ": Init module. Driver version %s\n", NISHIHARU_DRV_VER);

    if ( 0 > (char_major = edugra_pcie_register_chrdev(0, DRIVER_NAME)) )
    {
        pr_err(DRIVER_NAME ": Init Error, failed to call register_chrdev.\n");
        return char_major;
    }
    pr_notice("EduGraphics_pcie_driver registered with major number %d\n", char_major);

    // PCIドライバの登録
    int ret = pci_register_driver(&edugra_pci_driver);
    if (ret < 0) {
        pr_err("PCI driver registration failed\n");
        class_destroy(chardev_class);
        edugra_pcie_unregister_chrdev(char_major, DRIVER_NAME);
        return ret;
    }

    return 0;
}



// モジュールの終了関数
static void __exit edugra_pci_driver_exit(void) {
    pr_notice(DRIVER_NAME ": Exit module.\n");

    // デバイスとクラスのクリーンアップ
    device_destroy(chardev_class, MKDEV(0, 0));
    class_destroy(chardev_class);
}



module_init(edugra_pci_driver_init);
module_exit(edugra_pci_driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("NISHIHARU");
MODULE_DESCRIPTION("EduGraphics PCI Driver");
