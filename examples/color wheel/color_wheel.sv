// Color Wheel

module fsm #(
    parameter BLINK_INTERVAL = 2000000,     // CLK freq is 12MHz, so 2,000,000 cycles is 0.16666666667s
)(
    input logic     clk, 
    output logic    red, 
    output logic    green, 
    output logic    blue
);

    // Define state variable values
    localparam [2:0] RED = 3'b000;
    localparam [2:0] YELLOW = 3'b001;
    localparam [2:0] GREEN = 3'b011;
    localparam [2:0] CYAN = 3'b111;
    localparam [2:0] BLUE = 3'b110;
    localparam [2:0] MAGENTA = 3'b100;


    // Declare state variables
    logic [2:0] current_state = RED;
    logic [2:0] next_state;

    // Declare next output variables
    logic next_red, next_green, next_blue;


    // Declare counter for timing each state
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;

    // Register the next state of the FSM
    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL-1) begin
            current_state <= next_state;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end

    // Compute the next state of the FSM
    always_comb begin
        next_state = 2'bxx;
        case (current_state)
            RED: next_state = YELLOW;
            YELLOW: next_state = GREEN; 
            GREEN: next_state = CYAN;
            CYAN: next_state = BLUE;
            BLUE: next_state = MAGENTA;
            MAGENTA: next_state = RED;
        endcase
    end

    // Register the FSM outputs
    always_ff @(posedge clk) begin
        red <= next_red;
        green <= next_green;
        blue <= next_blue;
    end

    // Compute next output values
    always_comb begin
        next_red = 1'b0;
        next_green = 1'b0;
        next_blue = 1'b0;
        case (current_state)
            RED: 
                next_red = 1'b1;
            YELLOW: begin
                next_red = 1'b1; 
                next_green = 1'b1;
            end
            GREEN:
                next_green = 1'b1;
            CYAN: begin
                next_green = 1'b1;
                next_blue = 1'b1;
            end
            BLUE:
                next_blue = 1'b1;
            MAGENTA: begin
                next_red = 1'b1; 
                next_blue = 1'b1;
            end
        endcase
    end

endmodule
