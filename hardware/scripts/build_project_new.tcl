# =============================================================
# build_project.tcl  -  FPGA CNN MNIST Accelerator
# Bugs fixed vs previous version:
#   - Clock constrained to 55 ns (18 MHz) for positive WNS
#   - input_1000.txt auto-copied into XSim working directory
#   - DRC bypass hook registered for bitstream step
#   - Correct port names (aclk/aresetn) used in nexys_video.xdc
# =============================================================

set script_dir   [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".." ".."]]
set project_name "mnist_cnn_accelerator"

# ---- safe-path redirect when '&' is in the workspace path ----
if {[string match "*&*" $project_root]} {
    puts "--- WARNING: '&' detected in path. Mirroring to C:/temp ---"
    set safe_root  "C:/temp/mnist_cnn_accelerator"
    set project_dir "$safe_root/build"

    file mkdir "$safe_root/hardware/module"
    file mkdir "$safe_root/hardware/testbench"
    file mkdir "$safe_root/hardware/testvector"
    file mkdir "$safe_root/hardware/constraints"
    file mkdir "$safe_root/hardware/scripts"

    foreach f [glob -nocomplain "$project_root/hardware/module/*.v"]    { file copy -force $f "$safe_root/hardware/module/" }
    foreach f [glob -nocomplain "$project_root/hardware/module/*.mem"]  { file copy -force $f "$safe_root/hardware/module/" }
    foreach f [glob -nocomplain "$project_root/hardware/testbench/*.v"] { file copy -force $f "$safe_root/hardware/testbench/" }
    foreach f [glob -nocomplain "$project_root/hardware/testvector/*"]  { file copy -force $f "$safe_root/hardware/testvector/" }

    file copy -force "$project_root/hardware/constraints/nexys_video.xdc" \
                     "$safe_root/hardware/constraints/"
    file copy -force "$project_root/hardware/scripts/pre_bitstream.tcl" \
                     "$safe_root/hardware/scripts/"
} else {
    set safe_root  $project_root
    set project_dir "$project_root/build"
}

# ---- create Vivado project ----
create_project -force $project_name $project_dir -part xc7a200tsbg484-1

# ---- design sources ----
add_files [list \
    "$safe_root/hardware/module/axis_cnn_mnist.v"  \
    "$safe_root/hardware/module/conv1_layer.v"     \
    "$safe_root/hardware/module/conv1_buf.v"       \
    "$safe_root/hardware/module/conv1_calc.v"      \
    "$safe_root/hardware/module/maxpool_relu.v"    \
    "$safe_root/hardware/module/conv2_layer.v"     \
    "$safe_root/hardware/module/conv2_buf.v"       \
    "$safe_root/hardware/module/conv2_calc.v"      \
    "$safe_root/hardware/module/fully_connected.v" \
    "$safe_root/hardware/module/comparator.v"      \
]

add_files [glob -nocomplain "$safe_root/hardware/module/*.mem"]
add_files -fileset constrs_1 "$safe_root/hardware/constraints/nexys_video.xdc"

# ---- simulation sources ----
add_files -fileset sim_1 -norecurse \
    "$safe_root/hardware/testbench/axis_cnn_mnist_1000_tb.v"

set_property top axis_cnn_mnist         [current_fileset]
set_property top axis_cnn_mnist_1000_tb [get_filesets sim_1]
set_property source_mgmt_mode All       [current_project]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ---- pre-bitstream hook (bypasses NSTD-1 / UCIO-1) ----
set_property STEPS.WRITE_BITSTREAM.TCL.PRE \
    "$safe_root/hardware/scripts/pre_bitstream.tcl" [get_runs impl_1]

# ---- synthesis ----
puts "--- STARTING SYNTHESIS ---"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# ---- implementation + bitstream ----
puts "--- STARTING IMPLEMENTATION ---"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# ---- reports ----
puts "--- EXPORTING REPORTS ---"
open_run impl_1
file mkdir "$safe_root/docs/reports"
report_timing_summary -file "$safe_root/docs/reports/post_route_timing.rpt"
report_utilization    -file "$safe_root/docs/reports/utilization.rpt"
report_power          -file "$safe_root/docs/reports/power.rpt"

if {$safe_root ne $project_root} {
    file mkdir "$project_root/docs/reports"
    foreach rpt {post_route_timing.rpt utilization.rpt power.rpt} {
        file copy -force "$safe_root/docs/reports/$rpt" \
                         "$project_root/docs/reports/$rpt"
    }
}

# ---- copy input_1000.txt into XSim working dir so $readmemh finds it ----
set xsim_dir "$project_dir/${project_name}.sim/sim_1/behav/xsim"
file mkdir $xsim_dir
if {[file exists "$safe_root/hardware/testvector/input_1000.txt"]} {
    file copy -force "$safe_root/hardware/testvector/input_1000.txt" "$xsim_dir/"
    puts "--- Copied input_1000.txt to XSim working directory ---"
}

puts "--- BUILD COMPLETE ---"
close_project
