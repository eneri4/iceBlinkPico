`include "memory.sv"

module game_of_life #(
    parameter INIT_FILE = ""
)(
    input logic clk,
    input logic state,
    input [5:0] address,
    output logic [7:0] read_data,
);

    // declare idle counter & corresponding states
    logic [4:0] idle_counter;
    localparam TRANSMIT_FRAME = 1'b0;
    localparam IDLE = 1'b1;

    // declare memory module logic
    logic [1:0] write_flag;
    logic [7:0] pixel_val;
    logic [63:0] current_line;
    logic [63:0] previous_line;
    logic [63:0] next_line;

    // read and write params for memory
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    // neighbor and cell status logic
    logic [2:0] count;
    logic [8:0] alive_neighbors;
    localparam [7:0] DEAD = 8'h00;
    localparam [7:0] ALIVE = 8'hFF;

    // indexing neighbors logic
    logic [2:0] row; 
    assign row = address[5:3];
    logic [2:0] column;
    assign column= address[2:0];
    
    logic [7:0] start, previous_start,next_start;
    assign start = 8*column;
    assign previous_start = (start == 0) ? 56 : start - 8;
    assign next_start = (start == 56) ? 0 : start + 8;

    initial begin
        pixel_val = 8'b0;
        write_flag = WRITE;
        transmit_idle_register = 5'b000;
    end

    memory #(
        .INIT_FILE              (INIT_FILE)
    ) mem (
        .clk                    (clk),
        .write_flag             (write_flag),
        .pixel                  (address),
        .new_pixel_val          (pixel_val),
        .current_pixel_val      (read_data),
        .current_line           (current_line),
        .previous_line          (previous_line),
        .next_line              (next_line)
    );

    // check whenever mem outputs updated
    always_comb begin
        // reset for new frame
        count = 3'b000;
        alive_neighbors = 8'b0;

        // check neighbors' status (0 if dead, 1 if alive)
        alive_neighbors[0] = (previous_line[previous_start +:8] != 0);
        alive_neighbors[1] = (previous_line[start_index +: 8] != 0);
        alive_neighbors[2] = (previous_line[next_start +: 8] != 0);
        alive_neighbors[3] = (current_line[previous_start +: 8] !=0);
        alive_neighbors[4] = (current_line[next_start +: 8] !=0);
        alive_neighbors[5] = (next_line[previous_start +: 8] != 0);
        alive_neighbors[6] = (next_line[start_index +: 8] != 0);
        alive_neighbors[7] = (next_line[next_start +: 8] != 0);

        // count all alive neighbors
        counter = $countones(neighbors);
    end

    // check every clock cycle
    always_ff @(posedge clk) begin

        transmit_idle_register = {transmit_idle_register, state};
        if (write_flag == REPLACE) begin
            write_flag <= WRITE;
        end

        // next generation logic
        if (counter < 2 && read_data != DEAD) begin
            pixel_val <= DEAD;
        end else if ((counter == 2 || counter == 3) && read_data != DEAD) begin
            pixel_val <= ALIVE; 
        end else if (counter > 3 && read_data != DEAD) begin
            pixel_val <= DEAD; 
        end else if (counter == 3 && read_data == DEAD) begin
            pixel_val <= ALIVE; 
        end else begin
            pixel_val <= DEAD;
        end

        if (transmit_idle_register == 5'b11000) begin
            write_flag <= REPLACE;
        end

    end        


endmodule