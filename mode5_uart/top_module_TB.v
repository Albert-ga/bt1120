`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/26 15:26:27
// Design Name: 
// Module Name: SPI_bus_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module_TB(  );
	reg					clk				   ;
    reg					rst_n	           ;
    reg		[3:0]		a		           ;
    reg		[3:0]		b		           ;
	wire				byte_stop	       ;
	wire				TX		           ;	
    wire	[8:0]		c				   ;
	wire 				rx_byte_stop	   ;
	wire 	[7:0]		RX          	   ;	
	
  top_module #(
	.CNT		  				(109				)
  )top_module_uut(
	.clk						( clk				),	
    .rst_n	    				( rst_n	   			), 
    .a						    ( a				    ),
	.b							( b					),
	.c                  		( c					),
	.ready						( 1					),
	.byte_stop					( byte_stop			),
	.TX							( TX				),
	.rx_byte_stop				(rx_byte_stop  		),
	.RX          				(RX            		));


  reg [7:0] cnt;
  initial begin
    clk = 0;
	rst_n=0;
	#100;
	rst_n=1;
  end
  

  always #5	   clk = ~clk ;
  always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt <= 8'h00;
		a  	<= 4'h0;
		b  	<= 4'h0;
	end else if(cnt[7]==1)begin
		cnt <= 8'h00;
		a 	<= a + 1;
		b 	<= b + 2;
	end else begin
		cnt <= cnt + 1;
		a   <= a ;
		b   <= b ;
	end
  end	

  
endmodule
