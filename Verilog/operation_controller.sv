module operation_controller(
    input clock,
    input reset,
    input [3:1] phase,
    input [31:0] data_in,
    output [31:0] immediate,
    output reg [31:0] current_instruction,
    output [2:0] funct_3,
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
    output data_io_write_io,
    output data_io_read_io,
    output data_io_load,
/////Output Interface/////
    output pad_write_address,
    output pad_read,
    output pad_write,
    output [1:0]pad_data_size
);

///Registers
    reg [31:0] next_instruction;
    reg [31:0] last_instruction;
    reg flush_pipeline;

// instruction decoder
    wire operation_immediate = current_instruction[6:0] == 7'h13;
    wire load = current_instruction[6:0] == 7'h03;
    wire add_upp_immediate_pc = current_instruction[6:0] == 7'h17;
    wire store = current_instruction[6:0] == 7'h23;
    wire operation = current_instruction[6:0] == 7'h33 | operation_immediate;
    wire is_load_upper_immediate = current_instruction[6:0] == 7'h37;
    wire branch = current_instruction[6:0] == 7'h63;
    wire jump_and_link_register = current_instruction[6:0] == 7'h67;
    wire jump_and_link = current_instruction[6:0] == 7'h6f;
    wire system = current_instruction[6:0] == 7'h73;

// last instruction decoder
    wire load_second_part = last_instruction[6:0] == 7'h03;
    wire store_second_part = last_instruction[6:0] == 7'h23;

// register file addresses
    assign registers_addresses = 
        load_second_part & phase[2] ? 
            {last_instruction[24:15], last_instruction[11:7]} : 
            {current_instruction[24:15], current_instruction[11:7]};
    
// instructions function number
    wire [9:0] funct_10 = 
        load_second_part & phase[2] | store_second_part & phase[1] ? 
            {last_instruction[31:25], last_instruction[14:12]} : 
            {current_instruction[31:25], current_instruction[14:12]};
    wire [6:0] funct_7 = funct_10[9:3];
    assign funct_3 = funct_10[2:0];  
    assign op_function = operation ? {funct_7[5], funct_7[1], funct_3} :
                            branch ? 5'h10 : {~funct_3[2], 4'h5};

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
    assign load_upper_immediate = phase[3] & is_load_upper_immediate;

// register file
    assign register_file_write = 
        ((system | load | jump_and_link_register | jump_and_link | operation | add_upp_immediate_pc | is_load_upper_immediate) & phase[3]) | 
        (load_second_part & phase[2]);
    
    assign alu_use_pc = add_upp_immediate_pc;

    assign use_immediate = add_upp_immediate_pc | operation_immediate;

    assign pc_relative = branch | jump_and_link;

// program counter
    assign pc_read_next = phase[3] & (jump_and_link_register | jump_and_link);

    wire decoded_cnzv = 
        funct_3 == 3'h0 ? cnzv[2] : 
        funct_3 == 3'h1 ? ~cnzv[2] : 
        funct_3 == 3'h4 ? (cnzv[1] ^ cnzv[3]) : 
        funct_3 == 3'h5 ? ~(cnzv[1] ^ cnzv[3]) : 
        funct_3 == 3'h6 ? cnzv[0] : 
        funct_3 == 3'h7 ? ~cnzv[0] : 1'b0;

    wire jump = jump_and_link | jump_and_link_register | (branch & decoded_cnzv);

    assign pc_jump = phase[3] & jump;

    assign pc_use_offset = store;

    assign forward_address = phase[3] & (load | store);

// data io
    assign data_io_write_io = phase[1] & load_second_part;
    assign data_io_read_io = phase[1] & store_second_part;
    assign data_io_load = phase[2] & load_second_part;

// output interface
    assign pad_write_address = phase[1] | forward_address;
    assign pad_read = phase[2] | data_io_write_io;
    assign pad_write = data_io_read_io;
    assign pad_data_size = {funct_3[1], funct_3[1] | funct_3[0]};
//********************************************************************************************************************//
// registers update
    always @(posedge clock) begin
        if (reset) begin
            next_instruction <= 32'h00000013;
            current_instruction <= 32'h00000013;
            last_instruction <= 32'h00000013;
        end
        else if (phase[2]) begin
            next_instruction <= data_in;
            flush_pipeline <= 0;
        end
        else if (phase[3]) begin
            last_instruction <= current_instruction;
            current_instruction <= flush_pipeline ? 32'h00000013 : next_instruction;
        end

        if(jump)begin
            flush_pipeline <= 1;
        end
    end
endmodule
