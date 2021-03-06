
#include <stdio.h>
#include <io.h>
#include "sys/alt_irq.h"
#include "system.h"
#include "Image.c"
#include "Mountain.c"
#include "altera_avalon_performance_counter.h"

const int GPIO_WRITE_OFFSET = 4;
const int GPIO_CLEAR_OFFSET = 12;

void LCD_Write_Command(int command) {
  IOWR_32DIRECT(LCD_DMA_0_BASE,0,command);
}

void LCD_Write_Data(int data) {
  IOWR_32DIRECT(LCD_DMA_0_BASE,4,data);
}

void init_LCD() {
	IOWR_32DIRECT(GPIO_0_BASE, 0, 0xFFFFFFFF);
	//IOWR_32DIRECT(GPIO_0_BASE, GPIO_WRITE_OFFSET ,0x00000003); // set reset on and 16 bits mode
	//IOWR_32DIRECT(GPIO_0_BASE, GPIO_CLEAR_OFFSET, 0x40000003);
	int counter = 0;
	while (counter<5000){counter++;}   // include delay of at least 120 ms use your timer or a loop
	IOWR_32DIRECT(GPIO_0_BASE, GPIO_WRITE_OFFSET ,0x00000002); // set reset on and 16 bits mode
	counter = 0;
	while (counter<5000){counter++;}   // include delay of at least 120 ms use your timer or a loop
	IOWR_32DIRECT(GPIO_0_BASE, GPIO_CLEAR_OFFSET, 0x00000000); // set reset off and 16 bits mode and enable LED_CS
	//IOWR_32DIRECT(GPIO_0_BASE, GPIO_CLEAR_OFFSET, 0x40000000);
	counter = 0;
	while (counter<500){counter++;}   // include delay of at least 120 ms use your timer or a loop

	LCD_Write_Command(0x0028);     //display OFF
	LCD_Write_Command(0x0011);     //exit SLEEP mode
	LCD_Write_Data(0x0000);

	LCD_Write_Command(0x00CB);     //Power Control A
	LCD_Write_Data(0x0039);     //always 0x39
	LCD_Write_Data(0x002C);     //always 0x2C
	LCD_Write_Data(0x0000);     //always 0x00
	LCD_Write_Data(0x0034);     //Vcore = 1.6V
	LCD_Write_Data(0x0002);     //DDVDH = 5.6V

	LCD_Write_Command(0x00CF);     //Power Control B
	LCD_Write_Data(0x0000);     //always 0x00
	LCD_Write_Data(0x0081);     //PCEQ off
	LCD_Write_Data(0x0030);     //ESD protection

	LCD_Write_Command(0x00E8);     //Driver timing control A
	LCD_Write_Data(0x0085);     //non - overlap
	LCD_Write_Data(0x0001);     //EQ timing
	LCD_Write_Data(0x0079);     //Pre-chargetiming
	LCD_Write_Command(0x00EA);     //Driver timing control B
	LCD_Write_Data(0x0000);        //Gate driver timing
	LCD_Write_Data(0x0000);        //always 0x00

	LCD_Write_Data(0x0064);        //soft start
	LCD_Write_Data(0x0003);        //power on sequence
	LCD_Write_Data(0x0012);        //power on sequence
	LCD_Write_Data(0x0081);        //DDVDH enhance on

	LCD_Write_Command(0x00F7);     //Pump ratio control
	LCD_Write_Data(0x0020);     //DDVDH=2xVCI

	LCD_Write_Command(0x00C0);    //power control 1
	LCD_Write_Data(0x0026);
	LCD_Write_Data(0x0004);     //second parameter for ILI9340 (ignored by ILI9341)

	LCD_Write_Command(0x00C1);     //power control 2
	LCD_Write_Data(0x0011);

	LCD_Write_Command(0x00C5);     //VCOM control 1
	LCD_Write_Data(0x0035);
	LCD_Write_Data(0x003E);

	LCD_Write_Command(0x00C7);     //VCOM control 2
	LCD_Write_Data(0x00BE);

	LCD_Write_Command(0x00B1);     //frame rate control
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0010);

	LCD_Write_Command(0x003A);    //pixel format = 16 bit per pixel
	LCD_Write_Data(0x0055);

	LCD_Write_Command(0x00B6);     //display function control
	LCD_Write_Data(0x000A);
	LCD_Write_Data(0x00A2);

	LCD_Write_Command(0x00F2);     //3G Gamma control
	LCD_Write_Data(0x0002);         //off

	LCD_Write_Command(0x0026);     //Gamma curve 3
	LCD_Write_Data(0x0001);

	LCD_Write_Command(0x0036);     //memory access control = BGR
	LCD_Write_Data(0x0000);

	LCD_Write_Command(0x002A);     //column address set
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0000);        //start 0x0000
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x00EF);        //end 0x00EF

	LCD_Write_Command(0x002B);    //page address set
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0000);        //start 0x0000
	LCD_Write_Data(0x0001);
	LCD_Write_Data(0x003F);        //end 0x013F

	LCD_Write_Command(0x0029);

}

void drawImage(){
	LCD_Write_Command(0x002C);
	for(int i = 0; i < 240*320*2; i+=2){
		uint16_t color = (((uint16_t) mountain.pixel_data[i+1]) << 8) | mountain.pixel_data[i];
		uint8_t red = (color & 0b1111100000000000) >> 11;
		uint16_t green = (color & 0b0000011111100000);
		uint16_t blue = (color & 0b11111) << 11;
		color = blue | green | red;
		LCD_Write_Data(color);
		//LCD_Write_Data((((uint16_t) gimp_image.pixel_data[i]) << 8) | gimp_image.pixel_data[i+1]);
	}
}

void fillRed() {
	LCD_Write_Command(0x002C);
	for(int i = 0; i< 240*320*2; i+= 2){
		uint16_t color = 0x00FF;
		LCD_Write_Data(color);
	}
}

void setupDMAAddress(const uint8_t* address){
	IOWR_32DIRECT(LCD_DMA_0_BASE, 8, address);
}

void setupDMASize(int size){
	IOWR_32DIRECT(LCD_DMA_0_BASE, 12, size);
}

void startDMA(){
	IOWR_32DIRECT(LCD_DMA_0_BASE, 16, 0);
}

void useDMA(){
	setupDMAAddress(gimp_image.pixel_data);
	setupDMASize(320*240*2);
	LCD_Write_Command(0x002C);
	startDMA();
}


volatile int dmaDone = 0;

void timer_irq(void* context, alt_u32 id){
	PERF_END(PERFORMANCE_COUNTER_0_BASE, 2);
	dmaDone = 1;
	IOWR_32DIRECT(LCD_DMA_0_BASE, 20, 1);
}

int main()
{
	/*PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
	printf("Starting\n");
	//while(1){

	PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 1);
	int counter = 0;
	while(counter < 10000) {counter ++;}
	PERF_END(PERFORMANCE_COUNTER_0_BASE, 1);
	PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE, alt_get_cpu_freq(), 1, "Hello");*/
		//printf("status %d \n", IORD_16DIRECT(TIMER_0_BASE, 0));
	//}

	alt_irq_register(LCD_DMA_0_IRQ, (void*) 0, (alt_isr_func) timer_irq);

	init_LCD();
	int counter = 0;
	while(counter < 5000) {counter ++;}


	//drawImage();
	while(1){
		//fillRed();
		PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 1);
		drawImage();
		PERF_END(PERFORMANCE_COUNTER_0_BASE, 1);
		counter = 0;
		while(counter < 50000000){counter++;}

		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 2);
		dmaDone = 0;
		useDMA();
		while(dmaDone == 0);
		PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
		perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE, alt_get_cpu_freq(), 2, "Manual", "DMA");
		counter = 0;
		while(counter < 50000000){counter++;}
	}
	/*LCD_Write_Command(0x002C);
	for(int i = 0; i < 240*320; i++){
		LCD_Write_Data(0x00FF);
	}*/
	return 0;
}
