## Switches
# Input a (Switches 0 to 4)
set_property PACKAGE_PIN V17 [get_ports {a[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a[0]}]
set_property PACKAGE_PIN V16 [get_ports {a[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a[1]}]
set_property PACKAGE_PIN W16 [get_ports {a[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a[2]}]
set_property PACKAGE_PIN W17 [get_ports {a[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a[3]}]
set_property PACKAGE_PIN W15 [get_ports {a[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {a[4]}]

# Input b (Switches 5 to 9)
set_property PACKAGE_PIN V15 [get_ports {b[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b[0]}]
set_property PACKAGE_PIN W14 [get_ports {b[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b[1]}]
set_property PACKAGE_PIN W13 [get_ports {b[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b[2]}]
set_property PACKAGE_PIN V2 [get_ports {b[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b[3]}]
set_property PACKAGE_PIN T3 [get_ports {b[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {b[4]}]

# shift_amount (Switches 11 and 12 - skipped 10 for visual clarity on the board)
set_property PACKAGE_PIN R3 [get_ports {shift_amount[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {shift_amount[0]}]
set_property PACKAGE_PIN W2 [get_ports {shift_amount[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {shift_amount[1]}]

# alu_control (Switches 13, 14 and 15)
set_property PACKAGE_PIN U1 [get_ports {alu_control[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {alu_control[0]}]
set_property PACKAGE_PIN T1 [get_ports {alu_control[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {alu_control[1]}]
set_property PACKAGE_PIN R2 [get_ports {alu_control[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {alu_control[2]}]
 

## LEDs
# result (LEDs 0 to 4)
set_property PACKAGE_PIN U16 [get_ports {result[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {result[0]}]
set_property PACKAGE_PIN E19 [get_ports {result[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {result[1]}]
set_property PACKAGE_PIN U19 [get_ports {result[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {result[2]}]
set_property PACKAGE_PIN V19 [get_ports {result[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {result[3]}]
set_property PACKAGE_PIN W18 [get_ports {result[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {result[4]}]

# alu_flags (LEDs 12 to 15) - {N, Z, C, V}
# N (Negative) -> LED
set_property PACKAGE_PIN P3 [get_ports {alu_flags[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {alu_flags[3]}]
# Z (Zero) -> LED
set_property PACKAGE_PIN N3 [get_ports {alu_flags[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {alu_flags[2]}]
# C (Carry) -> LED
set_property PACKAGE_PIN P1 [get_ports {alu_flags[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {alu_flags[1]}]
# V (Overflow) -> LED
set_property PACKAGE_PIN L1 [get_ports {alu_flags[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {alu_flags[0]}]
