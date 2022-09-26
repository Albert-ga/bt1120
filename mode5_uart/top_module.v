module top_module #(
	parameter CNT  = 109
)(
	input clk,
	input rst_n,
	input [3:0] a,
	input [3:0] b,
	input  ready,
	output TX,
	output byte_stop,
	output [8:0] c,
	output [8:0] rx_byte_stop,
	output [7:0] RX
	);
    
    wire [8:0] c1,c2; 
    wire [8:0] c_r ;

    mul uut1(
        .clk   (clk   )  ,
        .rst_n (rst_n )  ,
        .a     (a     )  ,
        .b     (4'hc  )  ,
        .c     (c1     ));
    
    mul uut2(
        .clk   (clk   )  ,
        .rst_n (rst_n )  ,
        .a     (4'h5  )  ,
        .b     (b     )  ,
        .c     (c2     ));
    
    assign c_r = c1+c2;
	assign c = c_r;
	
  uart_tx #(
     .CNT(CNT)
   )uart_tx_uut (
	.clk		(	clk			),
	.rst_n		(	rst_n		),
	.c			(	c_r[8:1]	),
	.ready		(	ready		),
	.byte_stop	(	byte_stop	),
	.TX			(	TX			));
	
   uart_rx #(
	 .CNT(CNT)
   )uart_rx_uut  (
	.clk		 (	clk			),
	.rst_n		 (	rst_n		),
	.c			 (	TX			),
	.ready		 (	ready		),
	.rx_byte_stop(rx_byte_stop  ),
	.RX          (RX            )
	);
	

endmodule


module mul(
	input clk,
	input rst_n,
	input [3:0] a,
	input [3:0] b,
	output  [8:0] c
	);
    
    reg [7:0] c_r1  ; 
    reg [7:0] c_r2  ;
    reg [7:0] c_r3  ;
    reg [7:0] c_r4  ;
    
    always@(posedge clk)begin
        if(!rst_n)begin
			c_r1 <= 8'b0;
			c_r2 <= 8'b0;
			c_r3 <= 8'b0;
			c_r4 <= 8'b0;	
        end else begin
            c_r1[4:1] <= b[0]?a:4'h0; 
            c_r2[5:2] <= b[1]?a:4'h0; 
            c_r3[6:3] <= b[2]?a:4'h0; 
            c_r4[7:4] <= b[3]?a:4'h0; 
			
        end
    end     
    assign c = {4'b0,c_r1[4:1]}+{3'b0,c_r2[5:2],1'b0} + {2'b0,c_r3[6:3],2'b0} + {1'b0,c_r4[7:4],3'b0};
endmodule

module uart_tx #(
	parameter   CNT     =  109
)(
	input clk,
	input rst_n,
	input [7:0]c,
	input ready,
	output wire byte_stop,
	output wire TX
	);

   localparam  CLK_HZ  =  10e7;
			
   localparam  IDLE    = 4'h0  ,
			   SA_BIT  = 4'h1  ,
			   D_BIT1  = 4'h2  ,
			   D_BIT2  = 4'h3  ,
			   D_BIT3  = 4'h4  ,
			   D_BIT4  = 4'h5  ,
			   D_BIT5  = 4'h6  ,
			   D_BIT6  = 4'h7  ,
			   D_BIT7  = 4'h8  ,
			   D_BIT8  = 4'h9  ,
			   C_BIT   = 4'hA  ,
			   SP_BIT  = 4'hB  ,
			   EDN_BIT = 4'hC  ;
			  
	reg [15:0] baud_cnt;
	wire baud ;
	
	reg [3:0] curr_state,next_state;
	reg  byte_stop_r;
	reg [7:0] c_r;
	reg TX_r;
	
	always@(posedge clk)begin
		if(!rst_n)
			baud_cnt <= 16'h0000;
		else if(baud_cnt == CNT-1)
			baud_cnt <= 16'h0000;
		else
			baud_cnt <= baud_cnt + 1;
	end
	
	assign baud = (baud_cnt == CNT-1)?1'b1:1'b0 ;
	
	always@(posedge clk)begin
		if(!rst_n)
			curr_state <= IDLE;
		else
			curr_state <= next_state;
	end
	
	always@(*)begin
		if(!rst_n)begin
			TX_r = 1'b1;
		end else 
			case(curr_state) 
				IDLE  : 	next_state = ready?SA_BIT:IDLE;   
				SA_BIT: 	if (baud) begin TX_r = 1'b0;    next_state = D_BIT1;  end
				D_BIT1: 	if (baud) begin TX_r = c_r[0];  next_state = D_BIT2;  end
				D_BIT2: 	if (baud) begin TX_r = c_r[1];  next_state = D_BIT3;  end
				D_BIT3: 	if (baud) begin TX_r = c_r[2];  next_state = D_BIT4;  end
				D_BIT4: 	if (baud) begin TX_r = c_r[3];  next_state = D_BIT5;  end
				D_BIT5: 	if (baud) begin TX_r = c_r[4];  next_state = D_BIT6;  end
				D_BIT6: 	if (baud) begin TX_r = c_r[5];  next_state = D_BIT7;  end
				D_BIT7: 	if (baud) begin TX_r = c_r[6];  next_state = D_BIT8;  end
				D_BIT8: 	if (baud) begin TX_r = c_r[7];  next_state = C_BIT ;  end
				C_BIT :     if (baud) begin TX_r = c_r[0]^c_r[1]^c_r[2]^c_r[3]^
												   c_r[4]^c_r[5]^c_r[6]^c_r[7] ;  
												   next_state = SP_BIT ; 
									  end
				SP_BIT: 	if (baud) begin TX_r = 1'b1  ;  next_state = EDN_BIT ;end
				EDN_BIT:    next_state = IDLE; 
			endcase
	end
	
	always@(*)begin
		if(!rst_n)begin
			c_r = 8'h00;
			byte_stop_r = 1'b0;
		end else if(curr_state==EDN_BIT)begin
			c_r = c;
			byte_stop_r = 1'b1;
		end else begin
			c_r = c_r;
			byte_stop_r = 1'b0;
		end
	end
	
	assign byte_stop = byte_stop_r;
	assign TX = TX_r;
	
endmodule

module uart_rx #(
	parameter   CNT     =  109  //badus 921600
)(
	input clk,
	input rst_n,
	input c,
	input ready,
	output reg rx_byte_stop,
	output reg [7:0]RX
	);

	reg  c_r1;   //reg1
	reg  c_r2;	//reg1
	wire flag ;	
	reg  start_sig;   //check start_bit
	reg  fall_edge ;  
	reg [11:0] cnt;   //
	reg [10:0] RX_r;
	
	always@(posedge clk)begin
		if(!rst_n)begin
			c_r1 <= 1'b0;
			c_r2 <= 1'b0;
		end else begin
			c_r1 <= c;
			c_r2 <= c_r1;
		end
	end
	
	assign flag = c_r2 & !c_r1 ;  //fall_edge_sig    
	
	
	//avoid fall_edge_sig Spike Burr
	always@(posedge clk)begin
		if(!rst_n)begin
			fall_edge <= 1'b0;
		end else begin
			fall_edge <= flag;
		end
	end
	
	
	always@(posedge clk)begin
		if(!rst_n)begin
			cnt <= 12'h000;
			start_sig <= 1'b0;
			rx_byte_stop <= 1'b0;
		end else if(fall_edge==1'b1)begin
			start_sig <= 1'b1;
	    end else if(cnt==(CNT-1)/2+CNT*10+1)begin
			cnt <= 12'h000;
			start_sig <= 1'b0;
			rx_byte_stop <= 1'b1;
		end else if(ready&&start_sig)begin 
			cnt <= cnt + 12'h001;
		end else begin 
			cnt <= cnt ;
			start_sig <= start_sig;
			rx_byte_stop <= 1'b0;
		end 
	end
	
	
	always@(*)begin
		case(cnt)
		(CNT-1)/2+CNT*0-1:  RX_r[0]  = c_r2;  //  0  start_bit
		(CNT-1)/2+CNT*1-1:  RX_r[1]  = c_r2;  //  data_bit [0 ]
		(CNT-1)/2+CNT*2-1:  RX_r[2]  = c_r2;  //  data_bit [1 ]
		(CNT-1)/2+CNT*3-1:  RX_r[3]  = c_r2;  //  data_bit [2 ]
		(CNT-1)/2+CNT*4-1:  RX_r[4]  = c_r2;  //  data_bit [3 ]
		(CNT-1)/2+CNT*5-1:  RX_r[5]  = c_r2;  //  data_bit [4 ]
		(CNT-1)/2+CNT*6-1:  RX_r[6]  = c_r2;  //  data_bit [5 ]
		(CNT-1)/2+CNT*7-1:  RX_r[7]  = c_r2;  //  data_bit [6 ]
		(CNT-1)/2+CNT*8-1:  RX_r[8]  = c_r2;  //  data_bit [7 ]
		(CNT-1)/2+CNT*9-1:  RX_r[9]  = c_r2;  //  odd|even check_bit 
		(CNT-1)/2+CNT*10-1: RX_r[10] = c_r2;  // 1  stop_bit
		(CNT-1)/2+CNT*10+1: RX = RX_r[8:1]; 
			            
						//check  start_bit =0 && stop_bit =1 && check_bit = RX_r[1]^RX_r[2]^RX_r[3]^RX_r[4]^RX_r[5]^RX_r[6]^RX_r[7]^RX_r[8]
						/*
			             if(RX_r[9] == RX_r[1]^RX_r[2]^RX_r[3]^RX_r[4]^RX_r[5]^RX_r[6]^RX_r[7]^RX_r[8])begin
							RX = RX_r[8:1] ;
							rx_byte_stop = 1'b1;
						 end else begin
							RX = 8'h00;
							rx_byte_stop = 1'b0;
						 end
						 */
		endcase
	end
	
endmodule	
/*
module top_module (
    input  clka		,
	input  clkb 	,
    input  rst_n	,
	input  sig_a	,
    output sig_b
);
   
    reg trig;
	reg sig_b_r;
	reg sig_b_r1;
   
    always@(posedge clka or posedge rst_n)begin
		if(!rst_n)
			trig <= 0;
		else
			trig <= sig_a?~trig :trig;
   
    end
	
	always@(posedge clkb or posedge rst_n)begin
		if(!rst_n)begin
			sig_b_r  <= 1'b0; 
			sig_b_r1 <= 1'b0;
		end else begin
			sig_b_r  <= trig ;
			sig_b_r1 <= sig_b_r;
		end
	end
	
    assign sig_b = sig_b_r1 ^ sig_b_r;
    
endmodule

*/



