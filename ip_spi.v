//----------------------------------------
//Module name:	ip_spi
//Function: 	SPI interface 
//Creator:		Qi Fan 1994
//Virsion:		1.0
//Data: 		2018/11/xx
//----------------------------------------

module ip_spi(clk,rstn,cfg_apply,cfg_addr,cfg_data,spi_clk,spi_csn,data_bit);

	input 	clk,rstn,cfg_apply;
	input 	[3:0] cfg_addr,cfg_data;
	output spi_clk,spi_csn,data_bit;

//-------------Input Ports - wires-----------------------------
	wire	clk, rstn,cfg_apply;
	wire 	[3:0] cfg_addr,cfg_data;
	
//------------Output ports - wires or reg ---------------------
	reg 	spi_csn;
	wire 	spi_clk,data_bit;
	
	
	//-----Synchronize input signal, cfg_apply to 1 MHz----
	//use two FFs
	reg apply_delay, apply_syn,apply_syn2;
	
	always @(posedge clk or negedge rstn)begin
		if (!rstn) begin 
			apply_delay<=0;
			apply_syn<=0;
			apply_syn2<=0;
			end
		else begin 
			apply_delay<=cfg_apply;	//two FFs synchronize cfg_apply
			apply_syn<=apply_delay;
			
			apply_syn2<=apply_syn;//record the state of input cfg_appy  
		end 
	end 
	
	wire apply;
	assign apply=(!apply_syn2) & apply_syn;	//Signal 'apply' will be one pulse
	//-----end Synchronize input signal, cfg_apply to 1 MHz----
	
	
	//-----spi controller FSM------------
	//.....with 9 states (idle and S1-S8)
	//.....for the 8 cycles, each sending 1-bit  
	reg 	[3:0] state;

	always @ (posedge clk or negedge rstn) begin //FSM state transition
		if (!rstn)	state<=0;
		else begin 
			case (state)
				4'd0:	if (apply) state<=state+1'b1;//waiting to start
						else state<=4'd0;
				4'd8: state<=4'd0;			//go back to idle state
				default: state<=state+1'b1;//default go to next state
			endcase	
		end	
	end 
	
	always @(*)begin			//FSM  output
		if (!rstn) begin 
			spi_csn=1;		
		end 
		else begin 
			case (state)
				4'd0: 	spi_csn=1;
				default:	spi_csn=0;
			endcase 
		end
	end
	//-----end spi controller FSM------------
	
	//----shift register for the output data bit----
	reg 	[7:0] buff_load; //buffer address and data 
	always @ (posedge clk or negedge rstn) begin 
		if (!rstn)  buff_load<=8'b0;
		else 
			if (apply) 									// parallel load data to shift reg
				buff_load<={cfg_addr[3:0],cfg_data[3:0]};
			else 											// .. else start shifting
				buff_load<={buff_load[6:0],1'b0};
	end
	//----end shift register for the output data bit----
	
	//Assign outputs to driver SPI 
	assign spi_clk=(!clk)&(!spi_csn);	
	assign data_bit=buff_load[7];

endmodule 