
	module ms_riscv32_mp (input ms_riscv32_mp_clk_in, ms_riscv32_mp_rst_in, ms_riscv32_mp_instr_hready_in, ms_riscv32_mp_hresp_in, ms_riscv32_mp_data_hready_in, ms_riscv32_mp_eirq_in, ms_riscv32_mp_tirq_in, ms_riscv32_mp_sirq_in,
							 input [31:0] ms_riscv32_mp_data_in, ms_riscv32_mp_instr_in,
							 output [3:0] ms_riscv32_mp_dmwr_mask_out,
							 input [63:0] ms_riscv32_mp_rc_in,
							 
							 output ms_riscv32_mp_dmwr_req_out,
							 output [31:0] ms_riscv32_mp_imaddr_out, ms_riscv32_mp_dmaddr_out, ms_riscv32_mp_dmdata_out,
							 output [1:0] ms_riscv32_mp_data_htrans_out);
		
	parameter boot_address = 32'h0;
	
	parameter wb_alu = 3'b000;
	parameter wb_lu = 3'b001;
	parameter wb_imm = 3'b010;
	parameter wb_iadder_out = 3'b011;
	parameter wb_csr = 3'b100;
	parameter wb_pc_plus = 3'b101;
	
	wire misaligned_instr, mem_wr_req, flush, iadder_src, wr_en_csr_file, wr_en_integer_file, i_or_e, set_cause, set_epc, instret_inc, mie_clear, mie_set, misaligned_exception, mie, meie_out, mtie_out, msie_out, meip_out, mtip_out, msip_out, rf_wr_en_reg, csr_wr_en_reg, csr_wr_en_reg_file, integer_wr_en_reg_file, alu_src_reg, illegal_instr, branch_taken, misaligned_load, misaligned_store, trap_taken, load_unsigned_reg, load_unsigned, alu_src, csr_wr_en, rf_wr_en, su_wr_req;
	wire [1:0] pc_src, load_size_reg, load_size;
	wire [2:0] funct3, csr_op_reg, wb_mux_sel, wb_mux_sel_reg, imm_type, csr_op;
	wire [3:0] cause, cause_in, alu_opcode_reg, alu_opcode, mem_wr_mask, su_wr_mask;
	wire [4:0] rs1_addr, rs2_addr, rd_addr, rd_addr_reg;
	wire [6:0] opcode, funct7;
	wire [11:0] csr_addr, csr_addr_reg;
	wire [31:7] instr_31_to_7;
	wire [31:0] iaddr, pc, pc_plus_4, pc_mux, rs1, rs2, imm, imm_reg, rs1_reg, pc_reg2, lu_output, alu_result, csr_data, pc_plus_4_reg, iadder_out_reg, rs2_reg, wb_mux_out, alu_2nd_src_mux, next_pc, pc_reg, iadder_out, epc, trap_address, su_data_out, su_d_addr;
	
	
	msrv32_pc PC(.rst_in(ms_riscv32_mp_rst_in),
					 .ahb_ready_in(ms_riscv32_mp_instr_hready_in),
					 .pc_src_in(pc_src),
					 .epc_in(epc),
					 .trap_address_in(trap_address),
					 .branch_taken_in(branch_taken),
					 .iaddr_in(iaddr[31:1]),
					 .pc_in(pc),
					 .pc_plus_4_out(pc_plus_4),
					 .misaligned_instr_out(misaligned_instr),
					 .pc_mux_out(pc_mux),
					 .i_addr_out(ms_riscv32_mp_imaddr_out));
					 
	
	msrv32_reg_block_1 REG1 (.clk_in(ms_riscv32_mp_clk_in),
									 .rst_in(ms_riscv32_mp_rst_in),
									 .pc_mux_in(pc_mux),
									 .pc_out(pc));
									 
									 
	msrv32_instruction_mux ID (.flush_in(flush),
											 .instr_in(ms_riscv32_mp_instr_in),
											 .opcode_out(opcode),
											 .funct3_out(funct3),
											 .funct7_out(funct7),
											 .rs1_addr_out(rs1_addr),
											 .rs2_addr_out(rs2_addr),
											 .rd_addr_out(rd_addr),
											 .csr_addr_out(csr_addr),
											 .instr_31_7_out(instr_31_to_7));
											 
	
	msrv32_store_unit SU (.funct3_in(funct3[1:0]),
								 .ahb_ready_in(ms_riscv32_mp_data_hready_in),
								 .iadder_in(iaddr),
								 .rs2_in(rs2),
								 .mem_wr_req_in(mem_wr_req),
								 .data_out(ms_riscv32_mp_dmdata_out),
								 .d_addr_out(ms_riscv32_mp_dmaddr_out),
								 .wr_mask_out(ms_riscv32_mp_dmwr_mask_out),
								 .wr_req_out(ms_riscv32_mp_dmwr_req_out),
								 .ahb_htrans_out(ms_riscv32_mp_data_htrans_out));

	
	msrv32_decoder DEC (.opcode_in(opcode),
							  .funct7_5_in(funct7[5]),
							  .funct3_in(funct3),
							  .iadder_1_to_0_in(iaddr[1:0]),
							  .trap_taken_in(trap_taken),
							  .alu_opcode_out(alu_opcode),
							  .mem_wr_req_out(mem_wr_req),
							  .load_size_out(load_size),
							  .load_unsigned_out(load_unsigned),
							  .alu_src_out(alu_src),
							  .iadder_src_out(iadder_src),
							  .csr_wr_en_out(csr_wr_en),
							  .rf_wr_en_out(rf_wr_en),
							  .wb_mux_sel_out(wb_mux_sel),
							  .imm_type_out(imm_type),
							  .csr_op_out(csr_op),
							  .illegal_instr_out(illegal_instr),
							  .misaligned_load_out(misaligned_load),
							  .misaligned_store_out(misaligned_store));
							  
	msrv32_imm_generator IMG (.instr_in(instr_31_to_7),
									  .imm_type_in(imm_type),
									  .imm_out(imm));
												
												
	msrv32_imm_adder IMM_ADDER (.pc_in(pc),
										 .rs1_in(rs1),
										 .imm_in(imm),
										 .iadder_src_in(iadder_src),
										 .iadder_out(iaddr));
										 
					 
	msrv32_branch_unit BU (.opcode_6_to_2_in(opcode[6:2]),
								  .funct3_in(funct3),
								  .rs1_in(rs1),
								  .rs2_in(rs2),
								  .branch_taken_out(branch_taken));				 
	
	msrv32_integer_file IRF (.clk_in(ms_riscv32_mp_clk_in),
									 .reset_in(ms_riscv32_mp_rst_in),
									 .rs_1_addr_in(rs1_addr),
									 .rs_2_addr_in(rs2_addr),
									 .rs_1_out(rs1),
									 .rs_2_out(rs2),
									 .rd_addr_in(rd_addr_reg),
									 .wr_en_in(integer_wr_en_reg_file),
									 .rd_in(wb_mux_out));
									 
									 
	msrv32_wr_en_generator WREN (.flush_in(flush),
										  .rf_wr_en_reg_in(rf_wr_en_reg),
										  .csr_wr_en_reg_in(csr_wr_en_reg),
										  .wr_en_integer_file_out(integer_wr_en_reg_file),
										  .wr_en_csr_file_out(csr_wr_en_reg_file));	
				

		
						
			
	
										
										
	msrv32_reg_block2 REG2 (.rd_addr_in(rd_addr),
									.csr_addr_in(csr_addr),
									.rs1_in(rs1),
									.rs2_in(rs2),
									.pc_in(pc),
									.pc_plus_4_in(pc_plus_4),
									.iadder_in(iaddr),
									.imm_in(imm),
									.alu_opcode_in(alu_opcode),
									.load_size_in(load_size),
									.wb_mux_sel_in(wb_mux_sel),
									.csr_op_in(csr_op),
									.load_unsigned_in(load_unsigned),
									.alu_src_in(alu_src),
									.csr_wr_en_in(csr_wr_en),
									.rf_wr_en_in(rf_wr_en),
									.branch_taken_in(branch_taken),
									.clk_in(ms_riscv32_mp_clk_in),
									.reset_in(ms_riscv32_mp_rst_in),
									.rd_addr_reg_out(rd_addr_reg),
									.csr_addr_reg_out(csr_addr_reg),
									.rs1_reg_out(rs1_reg),
									.rs2_reg_out(rs2_reg),
									.pc_reg_out(pc_reg2),
									.pc_plus_4_reg_out(pc_plus_4_reg),
									.iadder_out_reg_out(iadder_out_reg),
									.imm_reg_out(imm_reg),
									.alu_opcode_reg_out(alu_opcode_reg),
									.load_size_reg_out(load_size_reg),
									.wb_mux_sel_reg_out(wb_mux_sel_reg),
									.csr_op_reg_out(csr_op_reg),
									.load_unsigned_reg_out(load_unsigned_reg),
									.alu_src_reg_out(alu_src_reg),
									.csr_wr_en_reg_out(csr_wr_en_reg),
									.rf_wr_en_reg_out(rf_wr_en_reg));									
								
	msrv32_load_unit LU (.load_size_in(load_size_reg),
								.load_unsigned_in(load_unsigned_reg),
								.data_in(ms_riscv32_mp_data_in),
								.iadder_1_to_0_in(iadder_out_reg[1:0]),
								.lu_output(lu_output),
								.ahb_resp_in(ms_riscv32_mp_hresp_in));
	

	msrv32_alu ALU (.op_1_in(rs1_reg),
						 .op_2_in(alu_2nd_src_mux),
						 .opcode_in(alu_opcode_reg),
						 .result_out(alu_result));
						 
						 
	msrv32_wb_mux_sel_unit WBMUX (.wb_mux_sel_reg_in(wb_mux_sel_reg),
											.alu_result_in(alu_result),
											.lu_output_in(lu_output),
											.imm_reg_in(imm_reg),
											.iadder_out_reg_in(iadder_out_reg),
											.csr_data_in(csr_data),
											.pc_plus_4_reg_in(pc_plus_4_reg),
											.rs2_reg_in(rs2_reg),
											.alu_source_reg_in(alu_src_reg),
											.wb_mux_out(wb_mux_out),
											.alu_2nd_src_mux_out(alu_2nd_src_mux));


	msrv32_csr_file CSRF (.clk_in(ms_riscv32_mp_clk_in),
								 .rst_in(ms_riscv32_mp_rst_in),
								 .wr_en_in(csr_wr_en_reg_file),
								 .csr_addr_in(csr_addr_reg),
								 .csr_op_in(csr_op_reg),
								 .csr_uimm_in(imm_reg[4:0]),
								 .csr_data_in(rs1_reg),
								 .csr_data_out(csr_data),
								 .pc_in(pc_reg2),
								 .iadder_in(iadder_out_reg),
								 .e_irq_in(ms_riscv32_mp_eirq_in),
								 .t_irq_in(ms_riscv32_mp_tirq_in),
								 .s_irq_in(ms_riscv32_mp_sirq_in),
								 .i_or_e_in(i_or_e),
								 .set_cause_in(set_cause),
								 .cause_in(cause),
								 .set_epc_in(set_epc),
								 .instret_inc_in(instret_inc),
								 .mie_clear_in(mie_clear),
								 .mie_set_in(mie_set),
								 .misaligned_exception_in(misaligned_exception),
								 .mie_out(mie),
								 .meie_out(meie),
								 .mtie_out(mtie),
								 .msie_out(msie),
								 .meip_out(meip),
								 .mtip_out(mtip),
								 .msip_out(msip),
								 .real_time_in(ms_riscv32_mp_rc_in),
								 .epc_out(epc),
								 .trap_address_out(trap_address));







msrv32_machine_control MC (.clk_in(ms_riscv32_mp_clk_in),
										.reset_in(ms_riscv32_mp_rst_in),
										.illegal_instr_in(illegal_instr),
										.misaligned_instr_in(misaligned_instr),
										.misaligned_store_in(misaligned_store),
										.opcode_6_to_2_in(opcode[6:2]),
										.funct3_in(funct3),
										.funct7_in(funct7),
										.rs1_addr_in(rs1_addr),
										.rs2_addr_in(rs2_addr),
										.rd_addr_in(rd_addr),
										.e_irq_in(ms_riscv32_mp_eirq_in),
										.t_irq_in(ms_riscv32_mp_tirq_in),
										.s_irq_in(ms_riscv32_mp_sirq_in),
										.i_or_e_out(i_or_e),
										.set_cause_out(set_cause),
										.cause_out(cause),
										.set_epc_out(set_epc),
										.instret_inc_out(instret_inc),
										.mie_clear_out(mie_clear),
										.mie_set_out(mie_set),
										.misaligned_exception_out(misaligned_exception),
										.mie_in(mie),
										.meie_in(meie),
										.mtie_in(mtie),
										.msie_in(msie),
										.meip_in(meip),
										.mtip_in(mtip),
										.msip_in(msip),
										.pc_src_out(pc_src),
										.flush_out(flush),
										.trap_taken_out(trap_taken));

											
	

						 
endmodule						 
	