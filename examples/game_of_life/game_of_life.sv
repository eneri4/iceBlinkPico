`include "memory.sv"

module game_of_life#(
    parameter INIT_FILE = ""
)(
    input logic clk, 
    input logic state, // This is 'transmit_pixel' from top.sv
    input logic [5:0] read_address, 
    output logic [7:0] read_data 
);
    // FIX 1: Add missing declarations for internal signals
    logic [7:0] color; // Declared signal to be used as write_data
    logic [7:0] neighbors; // Declared signal for neighbor states
    
    // FIX 2: Define IDLE for local use (assuming 'not transmitting' state = 0)
    localparam IDLE = 1'b0; 

    // define idle counter
    logic [4:0] transmit_idle_register ;
    // define variables for memory module
    // input
    // logic [7:0] color_value; // Removed, redundant with 'color'
    logic [1:0] write_flag;
    // output
    logic [63:0] previous_line;
    logic [63:0] current_line;
    logic [63:0] next_line;
    
    // define local params for switching write_flag
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;
    
    // assign variables for starting state
    // FIX 3: Removed illegal 'assign color = 8'b0;' as color is assigned in an always_ff block
    assign write_flag = WRITE;
    assign transmit_idle_register = 5'b0; // counter = 0


    // define variables for indexing pixel address & neighbors
    logic [2:0] row;
    logic [2:0] column;
    // FIX 4: Use 'read_address' consistently instead of undeclared 'pixel'
    assign row = read_address[5:3];
    assign column = read_address[2:0];

    logic [5:0] start_index;
    logic [5:0] prev_start_index;
    logic [5:0] next_start_index;
    // looking at only one of the RGB channels --> each pixel is 8 bits
    assign start_index = 8*column;
    assign prev_start_index = (start_index == 0) ? 56 : start_index - 8;
    // wrap around logic
    assign next_start_index = (start_index == 56) ? 0 : start_index + 8;
    // wrap around logic


    // define variables for counting neighbors
    logic [2:0] count;
    // up to 8 possible living neighbors

    // define variables for distinguishing DEAD or ALIVE
    // 8-bits to correlate to RGB brightness
    localparam [7:0] DEAD = 8'h00;
    localparam [7:0] ALIVE = 8'hFF;


    // initialize memory module
        memory #(
        .INIT_FILE      (INIT_FILE)
    ) mem_module (
        .clk                    (clk),
        .read_address           (read_address), // FIX: Use read_address
        .write_data             (color),        // FIX: Use declared 'color' signal
        .write_flag             (write_flag),
        .read_data              (read_data),
        .previous_line          (previous_line),
        .current_line           (current_line),
        .next_line              (next_line)
    );

    // count neighbors 
    always_comb begin
        // reset for every new update
        count = 3'b0;
        neighbors = 8'b0;

        neighbors[0] = (previous_line[prev_start_index +:8] !=0);
        neighbors[1] = (previous_line[start_index +:8] !=0);
        neighbors[2] = (previous_line[next_start_index +:8] !=0);
        neighbors[3] = (current_line[prev_start_index +:8] !=0);
        neighbors[4] = (current_line[next_start_index +:8] !=0);
        neighbors[5] = (next_line[prev_start_index +:8] !=0);
        neighbors[6] = (next_line[start_index +:8] !=0);
        neighbors[7] = (next_line[next_start_index +:8] !=0);

        count = $countones(neighbors);

    end


    // update ALIVE or DEAD based on clock edge
    always_ff @(posedge clk) begin

        // update register
        if (state == IDLE) begin
            if (transmit_idle_register == 5'd31)
                write_flag <= REPLACE;
            else
                transmit_idle_register <= transmit_idle_register + 1;
        end else begin
            transmit_idle_register <= 0;
        end

        // Conways Game of Life Rules:
        if (count < 2 && read_data != DEAD) begin // Underpopulation
            color <= DEAD;
        end else if ((count == 2 || count == 3) && read_data != DEAD) begin // Survival
            color <= ALIVE;
        end else if (count > 3 && read_data != DEAD) begin // Overpopulation
            color <= DEAD;
        end else if (count == 3 && read_data == DEAD) begin // Reproduction
            color <= ALIVE;
        end else begin
            color <= DEAD;
        end

    end

endmodule