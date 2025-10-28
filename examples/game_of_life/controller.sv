
module controller (
    input logic clk, 
    output logic load_sreg, 
    output logic transmit_pixel, 
    output logic [5:0] pixel, 
    output logic [4:0] frame 
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001; // state reading RGB channels
    localparam [2:0] LOAD_SREG      = 3'b010; // state loading register
    localparam [2:0] TRANSMIT_PIXEL = 3'b100; // state transmitting pixels

    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [19:0] IDLE_CYCLES       = 20'd351832;   // = 375000 - 64 x (360 + 2) for 32 frames / second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0]
    
    phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    logic [5:0] pixel_counter = 6'd0; // 6-bit counter for current pixel 0-63 (2^6 = 64)
    logic [4:0] frame_counter = 5'd0; // 5-bit counter for current frame 0-31 (2^5 = 32)
    logic [8:0] transmit_counter = 9'd0; // 9-bit counter for cycles to transmit a frame ((360+2)*64)
    logic [19:0] idle_counter = 20'd0; // 20-bit counter for cycles in IDLE or b/t frames

    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1); // logic assigning when transmit done
    assign idle_done = (idle_counter == IDLE_CYCLES - 1); // logic assigning when idle done

    // flip-flop b/t states and phases
    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    // logic computing next state
    always_comb begin
        next_state = 1'bx;
        unique case (state)
            TRANSMIT_FRAME:
                if ((pixel_counter == 6'd63) && (transmit_pixel_done))
                    next_state = IDLE;
                else
                    next_state = TRANSMIT_FRAME;
            IDLE:
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
                else
                    next_state = IDLE;
        endcase
    end

    // logic computing next transmit phase
    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS:
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    // increment pixel counter when done
    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin
            pixel_counter <= pixel_counter + 1;
        end
    end

    // increment frame counter when IDLE wait over
    always_ff @(negedge clk) begin
        if (idle_done) begin
            frame_counter <= frame_counter + 1;
        end
    end

    // increment frame counter during TRANSMIT 
    always_ff @(negedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin // incrememnt while in transmit pixel phase
            transmit_counter <= transmit_counter + 1;
        end
        else begin // reset otherwise
            transmit_counter <= 9'd0;
        end
    end

    //  incrememnt idle counter
    always_ff @(negedge clk) begin
        if (state == IDLE) begin 
            idle_counter <= idle_counter + 1;
        end
        else begin // reset if not in IDLE
            idle_counter <= 20'd0;
        end
    end

    assign pixel = pixel_counter; // define pixel
    assign frame = frame_counter; // define frame

    assign load_sreg = (transmit_phase == LOAD_SREG); // assign load register
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL); // assign transmit pixel

endmodule
