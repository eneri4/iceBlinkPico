module RGB_LED #(
    parameter int CLK_FREQ        = 12_000_000,
    parameter int PWM_MAX         = 1200, // max brightness
    parameter int STATE_COUNT     = 6,
    parameter int STATE_DURATION  = CLK_FREQ / STATE_COUNT, // # of clock cycles for each transition (~1666)
    parameter int UPDATE_INTERVAL = STATE_DURATION / PWM_MAX // # of clock cycles for brightness to increment by 1
)(
    input  logic clk,
    output logic [11:0] r_val,
    output logic [11:0] g_val,
    output logic [11:0] b_val
);
    // 6-state FSM --> 60 degree hue segments
    typedef enum logic [2:0] {
        RED_TO_YELLOW, YELLOW_TO_GREEN,
        GREEN_TO_CYAN, CYAN_TO_BLUE,
        BLUE_TO_MAGENTA, MAGENTA_TO_RED
    } state_t;

    // initial state
    state_t state = RED_TO_YELLOW;

    logic [21:0] state_counter = 0;
    logic [10:0] update_counter = 0;

    logic [11:0] r_pwm_val = PWM_MAX - 1;
    logic [11:0] g_pwm_val = 0;
    logic [11:0] b_pwm_val = 0;

    always_ff @(posedge clk) begin
        // tick every UPDATE_INTERVAL cycle
        if (update_counter == UPDATE_INTERVAL - 1) begin
            update_counter <= 0;
            case (state)
                RED_TO_YELLOW:   g_pwm_val <= g_pwm_val + 1;
                YELLOW_TO_GREEN: r_pwm_val <= r_pwm_val - 1;
                GREEN_TO_CYAN:   b_pwm_val <= b_pwm_val + 1;
                CYAN_TO_BLUE:    g_pwm_val <= g_pwm_val - 1;
                BLUE_TO_MAGENTA: r_pwm_val <= r_pwm_val + 1;
                MAGENTA_TO_RED:  b_pwm_val <= b_pwm_val - 1;
            endcase
        end else begin
            update_counter <= update_counter + 1;
        end

        // state transitions
        if (state_counter == STATE_DURATION - 1) begin
            state_counter <= 0;
            case (state)
                RED_TO_YELLOW:   state <= YELLOW_TO_GREEN;
                YELLOW_TO_GREEN: state <= GREEN_TO_CYAN;
                GREEN_TO_CYAN:   state <= CYAN_TO_BLUE;
                CYAN_TO_BLUE:    state <= BLUE_TO_MAGENTA;
                BLUE_TO_MAGENTA: state <= MAGENTA_TO_RED;
                MAGENTA_TO_RED:  state <= RED_TO_YELLOW;
            endcase
        end else begin
            state_counter <= state_counter + 1;
        end
    end

    assign r_val = r_pwm_val;
    assign g_val = g_pwm_val;
    assign b_val = b_pwm_val;
    
endmodule
