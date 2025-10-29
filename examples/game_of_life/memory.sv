
module memory #(
    parameter INIT_FILE = ""
)(
    input logic clk,
    input logic [1:0] write_flag,
    input logic [5:0] pixel, 
    input logic [7:0] new_pixel_val,

    output logic [7:0] current_pixel_val,
    output logic [63:0] current_line,
    output logic [63:0] previous_line,
    output logic [63:0] next_line
);

    logic [63:0] read_memory [0:7];
    logic [63:0] initial_write_memory [0:7];
    logic [511:0] write_memory;

    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    logic [2:0] row;
    assign row = pixel[5:3];
    logic [2:0] column;
    assign column = pixel[0:2];

    logic [7:0] start_index;
    assign start_index = 8*column;

    initial begin 
        $readmemh(INIT_FILE, read_memory);
        $readmemh(INIT_FILE, initial_write_memory);
    end


    always_ff @(posedge clk) begin
        
        current_line <= read_memory[row];
        previous_line <= (row == 0)? read_memory[7] : read_memory[row-1];
        next_line <= (row == 7)? read_memory[0] : read_memory[row+1];
        current_pixel_val <= read_memory[row][start_index+:8];

        case (write_flag)
            WRITE:
                write_memory[(row * 64) + start_index +: 8] <= new_pixel_val;
            REPLACE:
                begin
                    // read_memory[0] <= write_memory[0:63];
                    // read_memory[1] <= write_memory[64:127];
                    // read_memory[2] <= write_memory[128:191];
                    // read_memory[3] <= write_memory[192:255];
                    // read_memory[4] <= write_memory[256:319];
                    // read_memory[5] <= write_memory[320:383];
                    // read_memory[6] <= write_memory[384:447];
                    // read_memory[7] <= write_memory[448:511];
                    {read_memory[7], read_memory[6], read_memory[5], read_memory[4], 
                    read_memory[3], read_memory[2], read_memory[1], read_memory[0]
                    } <= write_memory;
                end
        endcase
    end

endmodule