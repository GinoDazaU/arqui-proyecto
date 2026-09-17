## Switches
# Input A (Switches 0 a 4)
set_property PACKAGE_PIN V17 [get_ports {A[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {A[0]}]
set_property PACKAGE_PIN V16 [get_ports {A[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {A[1]}]
set_property PACKAGE_PIN W16 [get_ports {A[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {A[2]}]
set_property PACKAGE_PIN W17 [get_ports {A[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {A[3]}]
set_property PACKAGE_PIN W15 [get_ports {A[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {A[4]}]

# Input B (Switches 5 a 9)
set_property PACKAGE_PIN V15 [get_ports {B[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {B[0]}]
set_property PACKAGE_PIN W14 [get_ports {B[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {B[1]}]
set_property PACKAGE_PIN W13 [get_ports {B[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {B[2]}]
set_property PACKAGE_PIN V2 [get_ports {B[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {B[3]}]
set_property PACKAGE_PIN T3 [get_ports {B[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {B[4]}]

# bshift (Switches 11 y 12 - saltamos el 10 para no confundirnos visualmente en la placa)
set_property PACKAGE_PIN R3 [get_ports {bshift[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {bshift[0]}]
set_property PACKAGE_PIN W2 [get_ports {bshift[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {bshift[1]}]

# AluControl (Switches 13, 14 y 15)
set_property PACKAGE_PIN U1 [get_ports {AluControl[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {AluControl[0]}]
set_property PACKAGE_PIN T1 [get_ports {AluControl[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {AluControl[1]}]
set_property PACKAGE_PIN R2 [get_ports {AluControl[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {AluControl[2]}]
 

## LEDs
# Result (Leds 0 a 4)
set_property PACKAGE_PIN U16 [get_ports {Result[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Result[0]}]
set_property PACKAGE_PIN E19 [get_ports {Result[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Result[1]}]
set_property PACKAGE_PIN U19 [get_ports {Result[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Result[2]}]
set_property PACKAGE_PIN V19 [get_ports {Result[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Result[3]}]
set_property PACKAGE_PIN W18 [get_ports {Result[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Result[4]}]

# AluFlags (Leds 12 a 15) - {N, Z, C, V}
# N (neg) → LED
set_property PACKAGE_PIN P3 [get_ports {AluFlags[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AluFlags[3]}]
# Z (zero) → LED
set_property PACKAGE_PIN N3 [get_ports {AluFlags[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AluFlags[2]}]
# C (carry) → LED
set_property PACKAGE_PIN P1 [get_ports {AluFlags[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AluFlags[1]}]
# V (overflow) → LED
set_property PACKAGE_PIN L1 [get_ports {AluFlags[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AluFlags[0]}]
