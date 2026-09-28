create_clock -name clk -period 1 [get_ports clk]

set_input_delay  0.25 -clock clk -max [get_ports {req_msg[*] req_val reset resp_rdy}]
set_output_delay 0.25 -clock clk -max [get_ports {req_rdy resp_msg[*] resp_val}]
