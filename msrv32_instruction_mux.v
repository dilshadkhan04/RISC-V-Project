
	module msrv32_instruction_mux (input flush_in, 
											 input [31:0] instr_in,
									
											 output [6:0] opcode_out, funct7_out,
											 output [2:0] funct3_out,
											 output [4:0] rs1_addr_out, rs2_addr_out, rd_addr_out,
											 output [11:0] csr_addr_out,
											 output [31:7] instr_31_7_out);
	
	reg [31:0] instr_mux;
	
	always @(*)
	begin
		if(flush_in)
			instr_mux = 32'h00000013;
		else
			instr_mux = instr_in;
	end
	
	assign opcode_out = instr_mux[6:0];
	assign funct3_out = instr_mux[14:12];
	assign funct7_out = instr_mux[31:25];
	assign csr_addr_out = instr_mux[31:20];
	assign rs1_addr_out = instr_mux[19:15];
	assign rs2_addr_out = instr_mux[24:20];
	assign rd_addr_out = instr_mux[11:7];							
	assign instr_31_7_out = instr_mux[31:7];
		
	endmodule
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									
									