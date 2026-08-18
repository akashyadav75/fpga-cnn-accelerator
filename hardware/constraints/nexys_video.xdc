## nexys_video.xdc
## Target Board: Nexys Video (Artix-7 XC7A200T-1SBG484C)

## Clock Signal (18 MHz for perfect timing closure)
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { aclk }];
create_clock -add -name sys_clk_pin -period 55.00 -waveform {0 27.5} [get_ports { aclk }];

## Reset Button (Active Low)
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS15 } [get_ports { aresetn }];

## USB-UART Interface (Nexys Video Physical Pins)
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { usb_uart_rxd }];
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { usb_uart_txd }];

## Downgrade DRC checks
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

