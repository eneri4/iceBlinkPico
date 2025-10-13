// RGB_LED test bench

`timescale 1ns/1ps

module RGB_LED_tb;

     parameter PWM_INTERVAL = 1200;

     logic clk = 0;
     logic led_r, led_g, led_b;

     top # (
          .PWM_INTERVAL  (PWM_INTERVAL)
     ) dut (
          .clk             (clk), 
          .RGB_R           (led_r),
          .RGB_G           (led_g),
          .RGB_B           (led_b)
     );

     initial begin
          $dumpfile("RGB_LED.vcd");
          // Dump dut signals and its internal controller signals
          $dumpvars(0, RGB_LED_tb);
          
          // Run for 1.2 seconds to see one full cycle and the start of the next
          #(1.2 * 1_000_000_000);
          $finish;
     end

     // Generate 12 MHz clock
     always begin 
          #4.1667 
          clk = ~clk;
     end

endmodule