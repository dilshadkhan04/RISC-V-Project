module msrv32_pc (input [31:1] iaddr_in,
				  input branch_taken_in, ahb_ready_in, rst_in,
				  input [1:0] pc_src_in,
				  input [31:0] epc_in, trap_address_in, pc_in,
				  				  
				  output [31:0] pc_plus_4_out,
				  output reg [31:0] i_addr_out, 
				  output reg [31:0] pc_mux_out,
				  output misaligned_instr_out);

parameter BOOT_ADDRESS = 0;
wire [31:0] next_pc;			  
				  
assign pc_plus_4_out = pc_in + 32'h4;

assign next_pc = (branch_taken_in)? {iaddr_in, 1'b0} : pc_plus_4_out;

assign misaligned_instr_out = next_pc[1] & branch_taken_in;

always @(*)
begin
	case(pc_src_in)
		
		2'b00	: pc_mux_out = BOOT_ADDRESS;
		2'b01	: pc_mux_out = epc_in;
		2'b10	: pc_mux_out = trap_address_in;
		2'b11	: pc_mux_out = next_pc;
		default	: pc_mux_out = next_pc;
		
	endcase
end

always @(*)
begin
	if(rst_in)
		i_addr_out = BOOT_ADDRESS;
	else if(ahb_ready_in)
		i_addr_out = pc_mux_out;
end

endmodule
