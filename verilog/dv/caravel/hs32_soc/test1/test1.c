#include "../../defs.h"

void main()
{
	// Reset
	reg_la0_ena = 0x00000000;    // [31:0]
	reg_la1_ena = 0xFFFFFFFF;    // [63:32]
	reg_la2_ena = 0xFFFFFFFF;    // [95:64]
	reg_la3_ena = 0xFFFFFFFF;    // [127:96]
	
	// Reset and control bus
	reg_la0_data = 0b01; // [0] is high means reset
	reg_la0_data = 0b00; // [0] is low means stop reset

	// Write
	((volatile uint32_t*) 0x30000000)[0] = 0x2400CAFE;
	((volatile uint32_t*) 0x30000000)[1] = 0x24100005;
	((volatile uint32_t*) 0x30000000)[2] = 0x34010001;
	((volatile uint32_t*) 0x30000000)[3] = 0x14210001;
	((volatile uint32_t*) 0x30000000)[4] = 0x50000000;

	// Release control and reset
	reg_la0_data = 0b11; // [1] is high means release control back to hs32
	reg_la0_data = 0b10;

	// Configure lower 8-IOs as user output
	// Observe counter value in the testbench
	/*reg_mprj_io_0 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_1 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_2 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_3 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_4 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_5 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_6 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_7 =  GPIO_MODE_USER_STD_OUTPUT;

    // Apply configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);*/
}
