/*
EduGPU_pcie_driver
*/
#ifndef _EDUGPU_DRIVER_UTILS_H_
#define _EDUGPU_DRIVER_UTILS_H_

#define edugpu_test_bit(pos,var_addr)  ((*var_addr) & (1<<(pos)))

static inline void edugpu_set_bit(int nr, u32* addr) {
	u32 mask = BIT_MASK(nr);
	u32 *p = addr + BIT_WORD(nr);

	*p  |= mask;
}

#endif // _EDUGPU_DRIVER_UTILS_H_