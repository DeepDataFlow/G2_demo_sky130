set cwd [file dirname [info script]]
analyze -format sverilog -hdl_library {work} $cwd/gcd.v

