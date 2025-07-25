# Clock
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clock }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clock}];


## LEDs
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { tx_done }]; #IO_L18P_T2_A24_15 Sch=led[0]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { serial_out }]; #IO_L24P_T3_RS1_15 Sch=led[1]


set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L24N_T3_RS0_15 Sch=sw[0]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { start_tx }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { SW[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sw[2]

=============================================

// Start Header : (A5A5)h - 16 bits - 1010
// Payload : (10)d, (20)d, (30)d - 24 bits
// Delimiter : (5A5A)h - 16 bits
//MSB first
module serial_com_tx (
    input clock,//100MHz
    input reset,
    input start_tx,
    //output
    output reg tx_done, 
    output serial_out

);

  wire locked;
  wire clk_out1;
  
    // Define the constants
    localparam START_HEADER = 16'hA5A5;//1010 0101 1010 0101
    localparam DELIMITER    = 16'h5A5A;
    localparam PAYLOAD1     = 8'd10; //8'h0A
    localparam PAYLOAD2     = 8'd20; //8'h14 - 0001 0100
    localparam PAYLOAD3     = 8'd30; //8'h1E - 0001 1110
    //MSB first
    reg serial_data;
    reg [5:0] cntr;
    wire [3:0] Delim_index;
  
    
    wire clk_625K;
    
  clk_wiz_0 pll_out
   (
    // Clock out ports
    .clk_out1(clk_out1),     // output clk_out1
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clock));      // input clk_in1
// INST_TAG_END ------ End INSTANTIATION Template ---------


    reg [3:0] clk_cntr = 0;
    always @ ( posedge clk_out1) begin
      clk_cntr <= clk_cntr +1'b1;
    end
    assign clk_625K = clk_cntr [3];
  
    always @ (posedge clk_625K) begin
        if (reset==1'b1) begin//Active High reset
            serial_data <= 1'b0;
            tx_done     <= 1'b0;
            cntr        <= 6'd0;
        end else begin
            if  (start_tx == 1'b1) begin
            // $display ("Serial data TX %b",serial_data);
            //Write logic
                if (cntr < 56) begin
                    cntr <= cntr + 1'b1;
                    tx_done  <= 1'b0;
                end else begin //Transmission Done
                    tx_done  <= 1'b1;
                end
                //Transmit logic
                if (cntr < 16) begin //Send the Start Header
                    serial_data <= START_HEADER [15-cntr];
                end else if  (cntr < 24) begin //10h = 1 0000 - 1 0 111
                    serial_data <= PAYLOAD1 [7-cntr[2:0]];//10000, 10001, 10111
                end else if  (cntr < 32) begin  //11 000
                    serial_data <= PAYLOAD2 [7-cntr[2:0]];
                end else if  (cntr < 40) begin  //11 000
                    serial_data <= PAYLOAD3 [7-cntr[2:0]];
                end else begin //101000 
                    serial_data <= DELIMITER [15-Delim_index];                    
                end
                
            end else begin
                serial_data <= 1'b0;
                cntr        <= 6'd0;          
            end
        end
    end

    assign serial_out = serial_data;
    assign Delim_index = {(~cntr[3]),cntr[2:0]};
    
    
    ila_0 ila_debug (
	.clk(clk_out1), // input wire clk


	.probe0(locked), // input wire [0:0]  probe0  
	.probe1(clk_cntr), // input wire [3:0]  probe1 
	.probe2(start_tx), // input wire [0:0]  probe2 
	.probe3(cntr), // input wire [5:0]  probe3 
	.probe4(tx_done), // input wire [0:0]  probe4 
	.probe5(serial_data), // input wire [0:0]  probe5 
	.probe6(Delim_index) // input wire [3:0]  probe6
);

endmodule
