
	restart

	delete wave *
	add wave *
	force sim:/dma_lcd_ctrl/Clk 1 0, 0 {10 ns} -r 20ns
	force sim:/dma_lcd_ctrl/reset 1 0, 0 100ns

	force sim:/dma_lcd_ctrl/avalon_address 000 0, 000 205ns, 001 225ns, 001 405ns, 000 425ns
	force sim:/dma_lcd_ctrl/avalon_wr 0 0, 1 205ns, 0 225ns, 1 405ns, 0 425ns
	force sim:/dma_lcd_ctrl/avalon_cs 0 0, 1 208ns, 0 228ns, 1 405ns, 0 425ns
	force sim:/dma_lcd_ctrl/avalon_write_data 16#XX 0, 16#2A 205ns, 16#XX 225ns, 16#CC 405ns, 16#XX 425ns

	run 600ns

