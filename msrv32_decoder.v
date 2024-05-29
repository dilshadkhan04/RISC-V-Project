
	module msrv32_decoder (input trap_taken_in, funct7_5_in, 
								  input [6:0] opcode_in, 
								  input [2:0] funct3_in,
								  input [1:0] iadder_1_to_0_in,
								  
								  output mem_wr_req_out, load_unsigned_out, alu_src_out, iadder_src_out, csr_wr_en_out, rf_wr_en_out, illegal_instr_out, misaligned_load_out, misaligned_store_out,
								  output [1:0] load_size_out,  
								  output [2:0] wb_mux_sel_out, imm_type_out, csr_op_out,
								  output [3:0] alu_opcode_out);
	
	reg is_branch, is_jal, is_jalr, is_auipc, is_lui, is_op, is_op_imm, is_load, is_store, is_system, is_misc_mem;
	reg is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi;
	
	wire is_csr, is_implemented_instr, mal_word, mal_half;
	
	
	always @(*) // Demux
	begin
		case(opcode_in[6:2])
		
			5'b11000	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000000001;
			5'b11011	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000000010;
			5'b11001	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000000100;
			5'b00101	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000001000;
			5'b01101	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000010000;
			5'b01100	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00000100000;
			5'b00100	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00001000000;
			5'b00000	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00010000000;
			5'b01000	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b00100000000;
			5'b11100	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b01000000000;
			5'b00011	: {is_misc_mem, is_system, is_store, is_load, is_op_imm, is_op, is_lui, is_auipc, is_jalr , is_jal, is_branch} = 11'b10000000000;
								
		endcase
	end
	
	always @(*) // sub block - Decoder
	begin
		case(funct3_in)
		
			3'b000	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, is_op_imm};
			3'b010	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {1'b0, 1'b0, 1'b0, 1'b0, is_op_imm, 1'b0};
			3'b100	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {1'b0, 1'b0, 1'b0, is_op_imm, 1'b0, 1'b0};
			3'b101	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {1'b0, 1'b0, is_op_imm, 1'b0, 1'b0, 1'b0};
			3'b110	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {1'b0, is_op_imm, 1'b0, 1'b0, 1'b0, 1'b0};
			3'b111	: {is_xori, is_ori, is_andi, is_sltiu, is_slti, is_addi} = {is_op_imm, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
					
		endcase
	end
	
	assign alu_opcode_out[3] = funct7_5_in & ~(is_addi | is_slti | is_sltiu | is_andi | is_ori | is_xori);
	
	assign is_csr = ((funct3_in[0] | funct3_in[1] | funct3_in[0]) & is_system);
	
	assign csr_wr_en_out = is_csr;
	
	assign alu_opcode_out[2:0] = funct3_in;

	assign load_size_out = funct3_in[1:0];
	
	assign load_unsigned_out = funct3_in[2];
	
	assign alu_src_out = opcode_in[5];
	
	assign iadder_src_out = is_load | is_store | is_jalr;
		
	assign rf_wr_en_out = is_lui | is_auipc | is_jalr | is_jal | is_op | is_load | is_csr | is_op_imm;
	
	assign wb_mux_sel_out [0] = is_load | is_auipc | is_jal | is_jalr;
	assign wb_mux_sel_out [1] = is_lui | is_auipc;
	assign wb_mux_sel_out [2] = is_csr | is_jal | is_jalr;
	
	assign imm_type_out [0] =  is_op_imm | is_load | is_jalr | is_jal | is_branch;
	assign imm_type_out [1] = is_branch | is_store | is_csr;
	assign imm_type_out [2] = is_lui | is_auipc | is_jal | is_csr;
	
	assign is_implemented_instr = opcode_in && 7'o1;
	
	assign csr_op_out = funct3_in;
	
	assign misaligned_load_out = (mal_word | mal_half) & is_load;
	
	assign misaligned_store_out = (mal_word | mal_half) & is_store;
	
	assign mem_wr_req_out = is_store & ((trap_taken_in & mal_word & mal_half) == 0);
	
	assign mal_word = ((funct3_in[1]) && (iadder_1_to_0_in != 2'b00))? 1'b1 : 1'b0;
	
	assign mal_half = ((funct3_in[1:0] == 2'b01) && (iadder_1_to_0_in[0] != 1'b0))? 1'b1 : 1'b0;
	
	
	assign illegal_instr_out = ~is_implemented_instr | ~opcode_in[1] | ~opcode_in[0];
	
	endmodule
	