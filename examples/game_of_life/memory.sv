
module memory #(
    parameter INIT_FILE = ""
)(
    input logic clk,
    input logic [1:0] write_flag,
    input logic [5:0] pixel, 
    input logic new_pixel_val, // 1 bit to represent MAX or MIN brightness

    output bit current_pixel_val, // 1 bit to represent MAX or MIN brightness
    output logic [7:0] current_line,
    output logic [7:0] previous_line,
    output logic [7:0] next_line
);

    logic [7:0] read_memory [0:7];
    logic [7:0] initial_write_memory [0:7];
    logic [63:0] write_memory;

    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    logic [2:0] row;
    assign row = pixel[5:3];
    logic [2:0] column;
    assign column = pixel[2:0];

    initial begin 
        $readmemb(INIT_FILE, read_memory);
        $readmemb(INIT_FILE, initial_write_memory);  
    end

    always_ff @(posedge clk) begin
        
        current_line <= read_memory[row];
        previous_line <= (row == 0)? read_memory[7] : read_memory[row-1];
        next_line <= (row == 7)? read_memory[0] : read_memory[row+1];
        current_pixel_val <= read_memory[row][column];

        case (write_flag)
            WRITE: 
                write_memory[(row*8)+column] <= new_pixel_val;
            REPLACE: begin
                {read_memory[7], read_memory[6], read_memory[5], read_memory[4], 
                read_memory[3], read_memory[2], read_memory[1], read_memory[0]
                } <= write_memory;
            end
            default:
                write_memory[(row*8)+column] <= new_pixel_val;

        endcase


    end

    // display frames as they are updated
    `ifndef SYNTHESIS
    always @(posedge clk) begin
        if (write_flag == REPLACE) begin
            int bit_index;
            $display("\nNext Frame:");
            for (int row = 0; row < 8; row++) begin
                for (int col = 0; col < 8; col++) begin
                    bit_index = (row * 8) + col;
                    $write("%b", write_memory[bit_index]);
                end
                $write("\n");
            end
        end
    end
    `endif



endmodule