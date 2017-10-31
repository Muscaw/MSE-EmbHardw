restart

delete wave *
add wave *
force sim:/lcd/Clk 1 0, 0 {10 ns} -r 20ns
force sim:/lcd/nReset 0 0, 1 100ns

force sim:/lcd/Address 0 0, 0 205ns, 1 225ns, 1 405ns, 0 425ns
force sim:/lcd/Write 0 0, 1 205ns, 0 225ns, 1 405ns, 0 425ns
force sim:/lcd/ChipSelect 0 0, 1 208ns, 0 228ns, 1 405ns, 0 425ns
force sim:/lcd/WriteData 16#XX 0, 16#2A 205ns, 16#XX 225ns, 16#CC 405ns, 16#XX 425ns


run 600ns
