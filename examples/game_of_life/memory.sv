module memory #(
    parameter INIT_FILE = ""
)(
    input  logic        clk,
    input  logic [5:0]  read_address, // 6-bit pixel index from 0-63
    input  logic [7:0]  write_data,   // 8-bit pixel value
    input  logic [1:0]  write_flag,
    output logic [7:0]  read_data,    // 8-bit pixel value
    output logic [63:0] previous_line,
    output logic [63:0] current_line,
    output logic [63:0] next_line
);
    // write flag states
    localparam [1:0] WRITE   = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    // define local 2D memory arrays 
    logic [63:0] initial_read_memory [0:7];
    logic [63:0] initial_write_memory [0:7];
    
    initial begin
        for (int i = 0; i < 8; i++) begin
            initial_read_memory[i] = 64'h0;
            initial_write_memory[i] = 64'h0;
        end
    end

    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, initial_read_memory);
        $readmemh(INIT_FILE, initial_write_memory);
    end

    // flatten memory arrays into 1D
    logic [511:0] read_memory;
    logic [511:0] write_memory;

    // compute row and column
    logic [2:0] row;
    logic [2:0] column;
    logic [8:0] base_index; // 0-511 bit index
    assign row        = read_address[5:3];
    assign column     = read_address[2:0];
    assign base_index = (row * 64) + (column * 8); // 8 bits per pixel

    always_ff @(posedge clk) begin
        // read line
        current_line  <= read_memory[row*64 +: 64];
        previous_line <= (row == 0) ? read_memory[7*64 +: 64] : read_memory[(row-1)*64 +: 64];
        next_line     <= (row == 7) ? read_memory[0 +: 64] : read_memory[(row+1)*64 +: 64];
        // read pixel
        read_data <= read_memory[base_index +: 8];
        // write logic
        case (write_flag)
            WRITE: begin
                write_memory[base_index +: 8] <= write_data;
            end
            REPLACE: begin
                read_memory <= write_memory;
            end
        endcase
    end

endmodule