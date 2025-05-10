#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0xfa61d21, "devm_kmalloc" },
	{ 0xa45f7f78, "pci_enable_device" },
	{ 0xa0f356a4, "pci_iomap" },
	{ 0x4a41ecb3, "class_destroy" },
	{ 0x9fd01338, "__pci_register_driver" },
	{ 0xcf2a6966, "up" },
	{ 0xc45b2ba, "pci_request_regions" },
	{ 0xf7327982, "remap_pfn_range" },
	{ 0x122c3a7e, "_printk" },
	{ 0x6cbbfc54, "__arch_copy_to_user" },
	{ 0x737adc86, "_dev_err" },
	{ 0x6626afca, "down" },
	{ 0xf311fc60, "class_create" },
	{ 0x387323c0, "pci_iounmap" },
	{ 0xdcb764ad, "memset" },
	{ 0xcb14fd0e, "pci_set_master" },
	{ 0xd9a5ea54, "__init_waitqueue_head" },
	{ 0x3c3ff9fd, "sprintf" },
	{ 0x729874bd, "device_create_with_groups" },
	{ 0xa30491df, "_dev_notice" },
	{ 0xede264d1, "pci_release_regions" },
	{ 0xd75c6742, "__register_chrdev" },
	{ 0x7d958a42, "device_destroy" },
	{ 0x323febe6, "__kmalloc_cache_noprof" },
	{ 0x12a4e128, "__arch_copy_from_user" },
	{ 0x225d41c1, "pci_disable_device" },
	{ 0xa65c6def, "alt_cb_patch_nops" },
	{ 0x1b63b024, "_dev_printk" },
	{ 0x3142be5e, "kmalloc_caches" },
	{ 0x6bc3fbc0, "__unregister_chrdev" },
	{ 0x39ff040a, "module_layout" },
};

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "9CD03D9986436E40BDC832C");
