`timescale 1s/1s
module operation_controller(
    input clock,
    input reset,
    input [2:1] phase,
    input [31:0] data_in,
    output [31:0] immediate,
    output reg [31:0] current_instruction,
/////CSR Controller
    output [9:0] current_decoded_instruction,
    input exception,
    input system_jump,
    input system_load,
/////Miscellaneous/////
    output load_upper_immediate,
/////Register File/////
    output [14:0] registers_addresses,
    output register_file_write,
/////Alu and Shifter/////
    input [3:0] cnzv,
    output [4:0] op_function,
    output alu_use_pc,
    output use_immediate,
/////Program Counter/////
    output pc_read_next,
    output pc_jump,
    output pc_relative,
    output pc_use_offset,
    output forward_address,
/////Data IO/////
    output reg [2:0] data_type,
    output input_buffer_write,
    output input_buffer_read,
/////Output Interface/////
    output pad_read,
    output pad_write,
    output [1:0]pad_data_size
);

///Registers
    reg [31:0] next_instruction;

// instruction decoder
    wire operation_immediate = current_instruction[6:0] == 7'h13;
    wire load = current_instruction[6:0] == 7'h03 | system_load;
    wire add_upp_immediate_pc = current_instruction[6:0] == 7'h17;
    wire store = current_instruction[6:0] == 7'h23;
    wire operation = current_instruction[6:0] == 7'h33 | operation_immediate;
    wire is_load_upper_immediate = current_instruction[6:0] == 7'h37;
    wire branch = current_instruction[6:0] == 7'h63;
    wire jump_and_link_register = current_instruction[6:0] == 7'h67;
    wire jump_and_link = current_instruction[6:0] == 7'h6f;
    wire system = current_instruction[6:0] == 7'h73;

    assign current_decoded_instruction = {
        system, jump_and_link, jump_and_link_register, branch, is_load_upper_immediate, 
        operation, store, add_upp_immediate_pc, operation_immediate, load
    };
// load second part
    reg load_second_part;
    reg [4:0] load_c_address;

// register file addresses
    assign registers_addresses = {
        current_instruction[24:15],
        load_second_part & phase[1] ? load_c_address : current_instruction[11:7]
    };

// instructions function number    
    wire [6:0] funct_7 = current_instruction[31:25];
    wire [2:0] funct_3 = current_instruction[14:12];
    
    //used in alu
    assign op_function = operation ? {funct_7[5], funct_7[1], funct_3} : 5'h10;
        
// immediate decoder
    assign immediate =  
        add_upp_immediate_pc | is_load_upper_immediate ? {current_instruction[31:12], 12'b0} :
        jump_and_link ? {{12{current_instruction[31]}}, current_instruction[19:12], current_instruction[20], current_instruction[30:21], 1'b0} :
        branch ? {{20{current_instruction[31]}}, current_instruction[7], current_instruction[30:25], current_instruction[11:8], 1'b0} :
        store ? {{20{current_instruction[31]}}, current_instruction[31:25], current_instruction[11:7]} : 
        {{20{current_instruction[31]}}, current_instruction[31:20]};


//********************************************************************************************************************//
// control signals decoding
// miscellaneous
    assign load_upper_immediate = phase[2] & is_load_upper_immediate;

// register file
    assign register_file_write = 
        ((system | jump_and_link_register | jump_and_link | operation | add_upp_immediate_pc | is_load_upper_immediate) & phase[2]) | 
        (load_second_part & phase[1]);
    
    assign alu_use_pc = add_upp_immediate_pc;

    assign use_immediate = add_upp_immediate_pc | operation_immediate;

    assign pc_relative = branch | jump_and_link;

// program counter
    assign pc_read_next = phase[2] & (jump_and_link_register | jump_and_link);

    wire decoded_cnzv = 
        funct_3 == 3'h0 ? cnzv[2] : 
        funct_3 == 3'h1 ? ~cnzv[2] : 
        funct_3 == 3'h4 ? (cnzv[1] ^ cnzv[3]) : 
        funct_3 == 3'h5 ? ~(cnzv[1] ^ cnzv[3]) : 
        funct_3 == 3'h6 ? cnzv[0] : 
        funct_3 == 3'h7 ? ~cnzv[0] : 1'b0;

    wire jump = jump_and_link | jump_and_link_register | (branch & decoded_cnzv);

    assign pc_jump = phase[2] & jump;
    wire flush_pipeline = pc_jump | system_jump;
    
    assign pc_use_offset = store;

    assign forward_address = phase[2] & (load | store);

// data io
    assign input_buffer_write = phase[2] & load;
    assign input_buffer_read = phase[1] & load_second_part;

// output interface
    assign pad_read = phase[1] | input_buffer_write;
    assign pad_write = phase[2] & store;
    assign pad_data_size = {funct_3[1], funct_3[1] | funct_3[0]};
//********************************************************************************************************************//
// registers update
    always @(posedge clock) begin
        if (reset) begin
            next_instruction <= 32'h00000013;
            current_instruction <= 32'h00000013;
            load_second_part <= 0;
            load_c_address <= 5'b0;
            data_type <= 3'b0;
        end
        else if (phase[1]) begin
            next_instruction <= data_in;
        end
        else if (phase[2]) begin
            load_second_part <= load;
            load_c_address <= current_instruction[11:7];
            data_type <= funct_3;
            current_instruction <= flush_pipeline ? 32'h00000013 : next_instruction;
        end
    end
endmodule
