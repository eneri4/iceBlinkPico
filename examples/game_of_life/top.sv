// `include "game_of_life.sv"
// `include "ws2812b.sv"
// `include "controller.sv"

module top(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT, 
    output logic    _48b, 
    output logic    _45a
);
    logic red_data;
    logic green_data;
    logic blue_data;

    logic [5:0] pixel;
    logic [4:0] frame;
    logic [10:0] address;

    logic [23:0] shift_reg = 24'd0;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    // logic [7:0] read_memory_out_g [7:0];
    // logic [7:0] read_memory_out_b [7:0];
    // logic [7:0] read_memory_out_r [7:0];

    
    assign address = { pixel };

    // Instance sample gol for green channel
    game_of_life #(
        .INIT_FILE      ("initial_config/oscillator.txt")
    ) u1 (
        .clk            (clk),
        .load_sreg      (load_sreg),
        .address        (pixel), 
        .read_data      (green_data)
        // .read_memory    (read_memory_out_g)
    );

    // Instance sample gol for blue channel
    game_of_life #(
        .INIT_FILE      ("initial_config/spaceship.txt")
    ) u2 (
        .clk            (clk),
        .load_sreg      (load_sreg),
        .address        (pixel), 
        .read_data      (blue_data)
        // .read_memory    (read_memory_out_b)
    );

    // Instance sample gol for red channel
    game_of_life #(
        .INIT_FILE      ("initial_config/still_life.txt")
    ) u3 (
        .clk            (clk),
        .load_sreg      (load_sreg),
        .address        (pixel), 
        .read_data      (red_data)
        // .read_memory    (read_memory_out_r)
    );

    // Instance the WS2812B output driver
    ws2812b u4 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

    // Instance the controller
    controller u5 (
        .clk            (clk), 
        .load_sreg      (load_sreg), 
        .transmit_pixel (transmit_pixel), 
        .pixel          (pixel), 
        .frame          (frame)
    );

    always_ff @(posedge clk) begin
        // if time to load another frame
        if (load_sreg) begin
            unique case ({ SW, BOOT })
                2'b00:
                    shift_reg <= { {8{green_data}} , 16'd0 }; // repetition operator to make data 8-bit value from 0-255
                2'b01:
                    shift_reg <= { 8'd0, {8{red_data}}, 8'd0 }; 
                2'b10:
                    shift_reg <= { 16'd0, {8{blue_data}} };
                2'b11:
                    shift_reg <= { {8{green_data}}, {8{red_data}}, {8{blue_data}} };
            endcase
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };

        end
    end

    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule