# ==============================================================================
# build_soc.tcl
# Automates the creation of a MicroBlaze SoC with the MNIST CNN Accelerator IP
# for Nexys Video (Artix-7).
#
# Steps performed:
#   1. Creates Vivado project.
#   2. Packages axis_cnn_mnist as a local Vivado IP.
#   3. Creates a Block Design (BD) containing MicroBlaze, AXI UART Lite,
#      AXI4-Stream FIFO, and the CNN IP.
#   4. Connects all clocks, resets, AXI, and AXI-Stream buses.
#   5. Runs Synthesis, Implementation, Bitstream generation.
#   6. Exports the hardware design (.xsa) for Vitis/software development.
# ==============================================================================

set script_dir   [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".." ".."]]
set project_name "mnist_cnn_soc"
set project_dir  "$project_root/build_soc"

# 1. Create Project
create_project -force $project_name $project_dir -part xc7a200tsbg484-1

# 2. Add Source Files for packaging
add_files [list \
    "$project_root/hardware/module/axis_cnn_mnist.v"  \
    "$project_root/hardware/module/conv1_layer.v"     \
    "$project_root/hardware/module/conv1_buf.v"       \
    "$project_root/hardware/module/conv1_calc.v"      \
    "$project_root/hardware/module/maxpool_relu.v"    \
    "$project_root/hardware/module/conv2_layer.v"     \
    "$project_root/hardware/module/conv2_buf.v"       \
    "$project_root/hardware/module/conv2_calc.v"      \
    "$project_root/hardware/module/fully_connected.v" \
    "$project_root/hardware/module/comparator.v"      \
]

add_files [glob -nocomplain "$project_root/hardware/module/*.mem"]
add_files -fileset constrs_1 "$project_root/hardware/constraints/nexys_video.xdc"

set_property top axis_cnn_mnist [current_fileset]
update_compile_order -fileset sources_1

# 3. Package the CNN Accelerator as a Custom IP
set ip_dir "$project_dir/ip_repo"
file mkdir $ip_dir
ipx::package_project -root_dir $ip_dir -vendor user.org -library user -taxonomy /UserIP -import_files -force
set core [ipx::current_core]
set_property name axis_cnn_mnist $core
set_property display_name "AXI-Stream MNIST CNN Accelerator" $core
set_property description "Hardware-accelerated 8-bit Q4.4 CNN for MNIST classification" $core

# Associate clock and reset interfaces for AXIS ports
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces aclk -of_objects $core]
set_property value "s_axis:m_axis" [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces aclk -of_objects $core]]

ipx::save_core $core
update_ip_catalog -rebuild

# 4. Create Block Design
create_bd_design "soc_design"

# Instantiate MicroBlaze and run basic automation
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0
apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { \
    local_mem {64KB} \
    ecc {None} \
    cache {None} \
    debug_module {Debug Only} \
    interrupt {None} \
} [get_bd_cells microblaze_0]

# Instantiate AXI UART Lite
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_0]

# Instantiate AXI4-Stream FIFO
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_0
# Enable both Transmit (TX) and Receive (RX) streaming interfaces
set_property -dict [list \
    CONFIG.C_USE_TX_DATA {1} \
    CONFIG.C_USE_RX_DATA {1} \
    CONFIG.C_TX_FIFO_DEPTH {512} \
    CONFIG.C_RX_FIFO_DEPTH {512} \
] [get_bd_cells axi_fifo_0]

# Instantiate our custom CNN IP
create_bd_cell -type ip -vlnv user.org:user:axis_cnn_mnist:1.0 axis_cnn_mnist_0

# Add external ports for Board clock, reset, and physical UART
create_bd_port -dir I -type clk aclk
set_property -dict [list CONFIG.FREQ_HZ {18181818}] [get_bd_ports aclk] ;# 18 MHz to guarantee timing closure

create_bd_port -dir I -type rst aresetn
set_property -dict [list CONFIG.POLARITY {ACTIVE_LOW}] [get_bd_ports aresetn]

create_bd_port -dir I usb_uart_rxd
create_bd_port -dir O usb_uart_txd

# Connect External Ports
connect_bd_net [get_bd_ports aclk] [get_bd_pins microblaze_0_Clk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]

connect_bd_net [get_bd_ports usb_uart_rxd] [get_bd_pins axi_uartlite_0/rx]
connect_bd_net [get_bd_ports usb_uart_txd] [get_bd_pins axi_uartlite_0/tx]

# Run Connection Automation for AXI infrastructure (Interconnect, Reset, Clocks)
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
    Master "/microblaze_0 (Periph)" \
    Clk "Auto" \
} [get_bd_intf_pins axi_uartlite_0/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
    Master "/microblaze_0 (Periph)" \
    Clk "Auto" \
} [get_bd_intf_pins axi_fifo_0/S_AXI]

# Connect AXI-Stream FIFO to CNN Accelerator
connect_bd_intf_net [get_bd_intf_pins axi_fifo_0/AXI_STR_TXD] [get_bd_intf_pins axis_cnn_mnist_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins axis_cnn_mnist_0/m_axis] [get_bd_intf_pins axi_fifo_0/AXI_STR_RXD]

# Connect Clock and Reset to the CNN Accelerator IP
connect_bd_net [get_bd_pins microblaze_0_Clk] [get_bd_pins axis_cnn_mnist_0/aclk]
connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_cnn_mnist_0/aresetn]

# Regenerate layout and validate design
regenerate_bd_layout
validate_bd_design
save_bd_design

# 5. Create HDL Wrapper and set as top
make_wrapper -files [get_files $project_dir/$project_name.srcs/sources_1/bd/soc_design/soc_design.bd] -top
add_files -norecurse $project_dir/$project_name.srcs/sources_1/bd/soc_design/hdl/soc_design_wrapper.v
set_property top soc_design_wrapper [current_fileset]
update_compile_order -fileset sources_1

# 6. Pre-Bitstream Hook to bypass DRCs
set_property STEPS.WRITE_BITSTREAM.TCL.PRE \
    "$project_root/hardware/scripts/pre_bitstream.tcl" [get_runs impl_1]

# 7. Compile Synthesis & Implementation
puts "--- STARTING SOCO SYNTHESIS ---"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

puts "--- STARTING SOC IMPLEMENTATION + BITSTREAM ---"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# 8. Export Hardware Platform (.xsa) for Software/Firmware compilation
puts "--- EXPORTING XSA PLATFORM ---"
write_hw_platform -fixed -include_bit -force -file "$project_root/soc_design_wrapper.xsa"

puts "--- SOC BUILD COMPLETE! ---"
puts "Hardware Platform exported to: $project_root/soc_design_wrapper.xsa"
close_project
