
`timescale 1ns / 1ps

module dma_controller_tb;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter LEN_WIDTH  = 16;

    // Clock and reset
    logic clk;
    logic rst_n;

    // CPU configuration
    logic start;
    logic [ADDR_WIDTH-1:0] src_addr_in;
    logic [ADDR_WIDTH-1:0] dst_addr_in;
    logic [LEN_WIDTH-1:0] transfer_len_in;

    // Read interface
    logic read_req;
    logic [ADDR_WIDTH-1:0] read_addr;
    logic read_valid;
    logic [DATA_WIDTH-1:0] read_data;

    // Write interface
    logic write_req;
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic write_ready;

    // Status
    logic busy;
    logic done;
    logic irq;

    // Simple word-addressed memory model.
    // The DMA supplies byte addresses, so addresses are
    // converted to word indices by dividing by 4.
    logic [DATA_WIDTH-1:0] mem [0:255];

    integer i;
    integer read_count;
    integer write_count;

    // DUT: Device Under Test
    dma_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .src_addr_in(src_addr_in),
        .dst_addr_in(dst_addr_in),
        .transfer_len_in(transfer_len_in),

        .read_req(read_req),
        .read_addr(read_addr),
        .read_valid(read_valid),
        .read_data(read_data),

        .write_req(write_req),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_ready(write_ready),

        .busy(busy),
        .done(done),
        .irq(irq)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Simple synchronous read response.
    // Keep read_valid high for one response cycle.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_valid <= 1'b0;
            read_data  <= '0;
        end else begin
            read_valid <= 1'b0;

            if (read_req && !read_valid) begin
                read_data  <= mem[read_addr >> 2];
                read_valid <= 1'b1;
            end
        end
    end

    // Accept writes when write_req is asserted.
    always @(posedge clk) begin
        if (rst_n && write_req && write_ready) begin
            mem[write_addr >> 2] <= write_data;
            write_count <= write_count + 1;
        end
    end

    // Test sequence
    initial begin
        // Initialize all testbench-driven signals.
        rst_n = 1'b0;
        start = 1'b0;
        src_addr_in = '0;
        dst_addr_in = '0;
        transfer_len_in = '0;
        write_ready = 1'b1;

        read_valid = 1'b0;
        read_data = '0;

        read_count = 0;
        write_count = 0;

        // Initialize memory.
        for (i = 0; i < 256; i = i + 1)
            mem[i] = '0;

        // Source words at byte addresses 200, 204, 208.
        mem[200 >> 2] = 32'h1111_AAAA;
        mem[204 >> 2] = 32'h2222_BBBB;
        mem[208 >> 2] = 32'h3333_CCCC;

        // Reset
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("--------------------------------");
        $display("TEST 1: Three-word DMA transfer");
        $display("--------------------------------");

        src_addr_in = 32'd200;
        dst_addr_in = 32'd500;
        transfer_len_in = 16'd3;

        // Start pulse
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        // Wait for completion, with a timeout.
        fork
            begin
                wait(done === 1'b1);
            end
            begin
                repeat (100) @(negedge clk);
                $fatal(1, "ERROR: DMA transfer timed out");
            end
        join_any
        disable fork;

        // Allow the final memory write to settle.
        @(negedge clk);

        // Check copied data.
        if (mem[500 >> 2] !== 32'h1111_AAAA)
            $fatal(1, "ERROR: Destination word 0 mismatch");

        if (mem[504 >> 2] !== 32'h2222_BBBB)
            $fatal(1, "ERROR: Destination word 1 mismatch");

        if (mem[508 >> 2] !== 32'h3333_CCCC)
            $fatal(1, "ERROR: Destination word 2 mismatch");

        $display("PASS: All three words copied correctly.");
        $display("Destination: %h %h %h",
                 mem[500 >> 2],
                 mem[504 >> 2],
                 mem[508 >> 2]);

        // Wait until controller returns to IDLE.
        wait(busy === 1'b0);
        repeat (2) @(negedge clk);

        $display("--------------------------------");
        $display("TEST 2: Zero-length transfer");
        $display("--------------------------------");

        src_addr_in = 32'd200;
        dst_addr_in = 32'd600;
        transfer_len_in = 16'd0;

        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        fork
            begin
                wait(done === 1'b1);
            end
            begin
                repeat (20) @(negedge clk);
                $fatal(1, "ERROR: Zero-length transfer timed out");
            end
        join_any
        disable fork;

        if (mem[600 >> 2] !== '0)
            $fatal(1, "ERROR: Zero-length transfer wrote data");

        $display("PASS: Zero-length transfer completed without writing.");

        $display("--------------------------------");
        $display("ALL TESTS PASSED");
        $display("--------------------------------");

        $finish;
    end

endmodule
