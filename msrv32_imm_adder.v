
	module msrv32_imm_adder (input [31:0] pc_in,
									 input [31:0] rs1_in,
									 input iadder_src_in,
									 input [31:0] imm_in,
									 
									 output [31:0] iadder_out);
									 
	reg [31:0] imm_adder_intermediate;
	
	always @(*)
	begin
		if(iadder_src_in)
			imm_adder_intermediate = rs1_in;
		else
			imm_adder_intermediate = pc_in;
	end
	
	assign iadder_out = imm_in + imm_adder_intermediate;
	
	endmodule