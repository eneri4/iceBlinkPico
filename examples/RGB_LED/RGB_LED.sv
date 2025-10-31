// RGB Controller to cycle through HSV color wheel
// Generates R, G, B duty cycle values for PWM modules.

module RGB_LED #(
    parameter CLK_FREQ = 12_000_000, // 1s cycle
    parameter PWM_MAX = 1200, // PWM resolution
    parameter STATE_DURATION = CLK_FREQ / 6, // 6 states for 60-degree segments of color wheel
    parameter UPDATE_INTERVAL = STATE_DURATION / PWM_MAX
)(
    input logic clk,
    output logic [$clog2(PWM_MAX)-1:0] r_val,
    output logic [$clog2(PWM_MAX)-1:0] g_val,
    output logic [$clog2(PWM_MAX)-1:0] b_val
);

    // Declare state variables
    typedef enum logic [2:0] {
        H0_60,      // R=MAX,  G=Up,   B=0
        H60_120,    // R=Down, G=MAX,  B=0
        H120_180,   // R=0,    G=Down, B=0
        H180_240,   // R=0,    G=0,    B=Up
        H240_300,   // R=Up,   G=0,    B=MAX
        H300_360    // R=MAX,  G=0,    B=Down
    } state_t;

    state_t current_state = H0_60; // First state: red --> yellow

    // Declare counter variables
    logic [$clog2(STATE_DURATION)-1:0] state_timer = 0; 
    logic [$clog2(UPDATE_INTERVAL)-1:0] update_timer = 0; 

    logic update_tick; // Signal to trigger PWM value update

    // Implement counter for timing state transitions
    always_ff @(posedge clk) begin
        if (state_timer == STATE_DURATION - 1)
            state_timer <= 0;
        else
            state_timer <= state_timer + 1;
    end

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (update_timer == UPDATE_INTERVAL - 1) begin
            update_timer <= 0;
            update_tick <= 1'b1;
        end else begin
            update_timer <= update_timer + 1;
            update_tick <= 1'b0;
        end
    end

    // Register and compute next state of FSM
    always_ff @(posedge clk) begin
        if (state_timer == STATE_DURATION - 1) begin
            case (current_state)
                H0_60:      current_state <= H60_120;
                H60_120:     current_state <= H120_180;
                H120_180:  current_state <= H180_240;
                H180_240:  current_state <= H240_300;
                H240_300:  current_state <= H300_360;
                H300_360:  current_state <= H0_60;
                default:     current_state <= H0_60;
            endcase
        end
    end

    // Increment / Decrement PWM value as appropriate given current state    
    always_ff @(posedge clk) begin
        if (update_tick) begin // Ramp updates
            case (current_state)
                H0_60:      g_val <= g_val + 1; 
                H60_120:    r_val <= r_val - 1; 
                H120_180:   g_val <= g_val - 1;
                H180_240:   b_val <= b_val + 1;
                H240_300:   r_val <= r_val + 1;
                H300_360:   b_val <= b_val - 1;
            endcase
        end

        if (state_timer == STATE_DURATION - 1) begin // State transitions
            case (current_state)
                H0_60:      g_val <= PWM_MAX - 1; 
                H60_120:    r_val <= 0;          
                H120_180:   g_val <= 0;          
                H180_240:   b_val <= PWM_MAX - 1; 
                H240_300:   r_val <= PWM_MAX - 1;
                H300_360:   b_val <= 0;           
            endcase
        end

        if (state_timer == 0 && current_state == H0_60) begin // First state
            r_val <= PWM_MAX - 1;
            g_val <= 0;
            b_val <= 0;
        end
    end



endmodule