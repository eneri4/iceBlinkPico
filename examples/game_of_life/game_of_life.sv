`include "memory.sv"

module game_of_life #(
    parameter INIT_FILE = ""
)(
    output logic debug,
    input logic clk,
    // input logic state,
    input logic load_sreg,
    input [5:0] address,
    output logic read_data // 1 bit to represent MAX or MIN brightness
);

    // declare idle counter & corresponding states
    // logic [4:0] idle_register;

    // declare memory module logic
    logic [1:0] write_flag;
    logic pixel_val; // 1 bit to represent MAX or MIN brightness
    logic [7:0] current_line;
    logic [7:0] previous_line;
    logic [7:0] next_line;

    // read and write params for memory
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

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
    
    logic [3:0] start, previous_start,next_start;
    assign start = column;
    assign previous_start = (start == 0) ? 7 : start - 1;
    assign next_start = (start == 7) ? 0 : start + 1;

    initial begin
        pixel_val = 1'b0;
        write_flag = WRITE;
        idle_register = 5'b0;
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
        alive_neighbors[0] = (previous_line[previous_start] != 0);
        alive_neighbors[1] = (previous_line[start] != 0);
        alive_neighbors[2] = (previous_line[next_start] != 0);
        alive_neighbors[3] = (current_line[previous_start] !=0);
        alive_neighbors[4] = (current_line[next_start] !=0);
        alive_neighbors[5] = (next_line[previous_start] != 0);
        alive_neighbors[6] = (next_line[start] != 0);
        alive_neighbors[7] = (next_line[next_start] != 0);

        // count all alive neighbors
        count = $countones(alive_neighbors);

    end


    // check every clock cycle
    always_ff @(posedge clk) begin

        if (address == 6'd63) begin
            write_flag <= REPLACE;
        end else if (load_sreg) begin
            write_flag <= WRITE;
        end

        if (read_data) begin
            pixel_val <= (count == 2 || count == 3);
        end else begin
            pixel_val <= (count == 3);
        end


    end        


endmodule