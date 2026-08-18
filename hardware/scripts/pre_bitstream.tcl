# pre_bitstream.tcl
# Downgrade DRC checks for Unconstrained/Default I/O ports before generating bitstream
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
