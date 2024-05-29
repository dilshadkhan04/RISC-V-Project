 
	module msrv32_branch_unit (input [31:0] rs1_in, rs2_in,
							  input [6:2] opcode_6_to_2_in,
							  input [2:0] funct3_in,
							  
							  output reg branch_taken_out);
	
	parameter opcode_branch = 5'b11000;
	parameter opcode_jal = 5'b11011;
	parameter opcode_jalr = 5'b11001;
	
	reg take;
	
	always @(*)
	begin
		case(funct3_in)
		
			3'b000	:	take = (rs1_in == rs2_in);
			3'b001	:	take = !(rs1_in == rs2_in);
			3'b100	:	take = (rs1_in[31] ^ rs2_in[31])? rs1_in[31] : (rs1_in < rs2_in);
			3'b101	:	take = (rs1_in[31] ^ rs2_in[31])? ~rs1_in[31] : !(rs1_in < rs2_in);
			3'b110	:	take = (rs1_in < rs2_in);
			3'b111	:	take = !(rs1_in < rs2_in);
			default	:	take = 1'b0;
			
		endcase
	end
	
	always @(*)
	begin
		case(opcode_6_to_2_in [6:2])
		
			opcode_jal		:	branch_taken_out = 1'b1;
			opcode_jalr		:	branch_taken_out = 1'b1;
			opcode_branch	:	branch_taken_out =  take;
			default			:	branch_taken_out = 1'b0;
	
		endcase
	end
	
	endmodule