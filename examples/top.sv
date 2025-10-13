// `include "pwm.sv"
// `include "RGB_LED.sv"

// Top-level module for RGB LED Fader

module top #(
    parameter PWM_INTERVAL = 1200       
)(
    input  logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    // Duty cycle (brightness) values 
    // Calculate bit width storing values from 0 to PWM_interval
    logic [$clog2(PWM_INTERVAL)-1:0] r_pwm_val;
    logic [$clog2(PWM_INTERVAL)-1:0] g_pwm_val;
    logic [$clog2(PWM_INTERVAL)-1:0] b_pwm_val;
   
    // Raw PWM output 
    // Single-bit
    logic r_pwm_out;
    logic g_pwm_out;
    logic b_pwm_out;

    // RGB_LED instance 
    RGB_LED #(
        .PWM_MAX   (PWM_INTERVAL)
    ) ctrl (
        .clk        (clk),
        .r_val      (r_pwm_val),
        .g_val      (g_pwm_val),
        .b_val      (b_pwm_val)
    );

    // PWM generator instances for R, G, and B
    pwm #( 
        .PWM_INTERVAL(PWM_INTERVAL) 
    ) pwm_r (
        .clk        (clk),
        .pwm_value  (r_pwm_val),
        .pwm_out    (r_pwm_out)
    );

    pwm #( 
        .PWM_INTERVAL(PWM_INTERVAL) 
    ) pwm_g (
        .clk        (clk),
        .pwm_value  (g_pwm_val),
        .pwm_out    (g_pwm_out)
    );

    pwm #( 
        .PWM_INTERVAL(PWM_INTERVAL) 
    ) pwm_b (
        .clk        (clk),
        .pwm_value  (b_pwm_val),
        .pwm_out    (b_pwm_out)
    );

    // Assign PWM output wires to 
    // Invert outputs for common-anode LED
    assign RGB_R = ~r_pwm_out;
    assign RGB_G = ~g_pwm_out;
    assign RGB_B = ~b_pwm_out;


endmodule
