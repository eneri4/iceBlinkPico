module game_of_life #(
    parameter INIT_FILE = ""
)(
    input logic clk,
    // input logic state,
    input logic load_sreg,
    input [5:0] address,
    output logic read_data // 1 bit to represent MAX or MIN brightness
);

    // declare memory module logic
    logic [7:0] read_memory [7:0];
    // logic [7:0] initial_write_memory [7:0];
    logic [63:0] write_memory; 

    // read and write params for memory
    logic [1:0] write_flag;
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    logic new_pixel_val; // 1 bit to represent MAX or MIN brightness


    // neighbor and cell status logic
    logic [2:0] count;
    logic [8:0] alive_neighbors;
    localparam DEAD = 1'b0;
    localparam ALIVE = 1'b1;

    // indexing neighbors logic
    logic [2:0] row;
    assign row = address[5:3];
    logic [2:0] column;
    assign column = address[2:0];

    logic [7:0] current_line;
    logic [7:0] previous_line;
    logic [7:0] next_line;
 
    
    logic [2:0] current_col, previous_col, next_col;
    assign current_col = column;
    assign previous_col = (current_col == 0) ? 7 : current_col - 1;
    assign next_col = (current_col == 7) ? 0 : current_col + 1;

    initial begin

        $readmemb(INIT_FILE, read_memory);

        new_pixel_val = 1'b0;
        write_flag = WRITE;

    end

    // update pixel value
    always_ff @(negedge clk) begin
        
        current_line = read_memory[row];
        previous_line = (row == 0)? read_memory[7] : read_memory[row-1];
        next_line = (row == 7)? read_memory[0] : read_memory[row+1];
        read_data = read_memory[row][column];

        // reset for new frame
        count = 3'b000;
        alive_neighbors = 8'b0;

        // check neighbors' status (0 if dead, 1 if alive)
        alive_neighbors[0] = (previous_line[previous_col] != 0);
        alive_neighbors[1] = (previous_line[current_col] != 0);
        alive_neighbors[2] = (previous_line[next_col] != 0);
        alive_neighbors[3] = (current_line[previous_col] !=0);
        alive_neighbors[4] = (current_line[next_col] !=0);
        alive_neighbors[5] = (next_line[previous_col] != 0);
        alive_neighbors[6] = (next_line[current_col] != 0);
        alive_neighbors[7] = (next_line[next_col] != 0);

        // count all alive neighbors
        count = alive_neighbors[0] + alive_neighbors[1] + alive_neighbors[2] + alive_neighbors[3] + alive_neighbors[4] + alive_neighbors[5] + alive_neighbors[6] + alive_neighbors[7];

        // compute new state of pixel
        if (read_memory[row][column]) begin
            new_pixel_val = (count == 2 || count == 3);
        end else begin
            new_pixel_val = (count == 3);
        end

    end

    //update memories
    always_ff @(posedge clk) begin

        if (load_sreg) begin
            if (address == 6'd63) begin
                write_flag <= REPLACE;  // replace old memory (frame) after last pixel
            end else begin
                write_flag <= WRITE;     // continue writing to buffer for any other pixel
            end
        end
        
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

endmodule