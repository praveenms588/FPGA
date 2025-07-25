## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clock }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clock}];

## LEDs
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { LED}]; #IO_L18P_T2_A24_15 Sch=led[0]

module PROJECT3(
input clock,
output LED
    );
    reg [26:0] counter=0;
    always@(posedge clock)begin
    counter <= counter+1'b1;
    end
    assign LED=counter>=27'd100000000;
endmodule
