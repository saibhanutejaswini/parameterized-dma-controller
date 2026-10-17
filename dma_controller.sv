
module dma_controller #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int LEN_WIDTH  = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // CPU configuration interface
    input  logic                  start,
    input  logic [ADDR_WIDTH-1:0] src_addr_in,
    input  logic [ADDR_WIDTH-1:0] dst_addr_in,
    input  logic [LEN_WIDTH-1:0]  transfer_len_in,

    // Memory read interface
    output logic                  read_req,
    output logic [ADDR_WIDTH-1:0] read_addr,
    input  logic                  read_valid,
    input  logic [DATA_WIDTH-1:0] read_data,

    // Memory write interface
    output logic                  write_req,
    output logic [ADDR_WIDTH-1:0] write_addr,
    output logic [DATA_WIDTH-1:0] write_data,
    input  logic                  write_ready,

    // Status outputs
    output logic                  busy,
    output logic                  done,
    output logic                  irq
);

    // --------------------------------------------------
    // FSM state definitions
    // --------------------------------------------------

    typedef enum logic [2:0] {
        IDLE,
        READ,
        WAIT_READ,
        WRITE,
        CHECK,
        DONE
    } state_t;

    state_t state, next_state;

    // --------------------------------------------------
    // Internal registers
    // --------------------------------------------------

    logic [ADDR_WIDTH-1:0] src_addr_reg;
    logic [ADDR_WIDTH-1:0] dst_addr_reg;

    logic [LEN_WIDTH-1:0] remaining_words;

    logic [DATA_WIDTH-1:0] data_buffer;

    logic start_d;
    logic start_pulse;

    logic done_reg;

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    // Detect a rising edge on start.
    assign start_pulse = start && !start_d;

    // --------------------------------------------------
    // Start edge detection
    // --------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_d <= 1'b0;
        else
            start_d <= start;
    end

    // --------------------------------------------------
    // FSM state register
    // --------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // --------------------------------------------------
    // Next-state logic
    // --------------------------------------------------

    always_comb begin
        next_state = state;

        case (state)

            IDLE: begin
                if (start_pulse) begin
                    if (transfer_len_in == '0)
                        next_state = DONE;
                    else
                        next_state = READ;
                end
            end

            // Assert the read request.
            READ: begin
                next_state = WAIT_READ;
            end

            // Wait for the memory response.
            WAIT_READ: begin
                if (read_valid)
                    next_state = WRITE;
            end

            // Hold write request until accepted.
            WRITE: begin
                if (write_ready)
                    next_state = CHECK;
            end

            // The counter is decremented after each
            // accepted write.
            CHECK: begin
                if (remaining_words == '0)
                    next_state = DONE;
                else
                    next_state = READ;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // --------------------------------------------------
    // Address generator, counter and data buffer
    // --------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_reg    <= '0;
            dst_addr_reg    <= '0;
            remaining_words <= '0;
            data_buffer     <= '0;
            done_reg        <= 1'b0;
        end else begin

            // Default: completion is a one-cycle pulse.
            done_reg <= 1'b0;

            // Capture transfer configuration.
            if (state == IDLE && start_pulse) begin
                src_addr_reg    <= src_addr_in;
                dst_addr_reg    <= dst_addr_in;
                remaining_words <= transfer_len_in;
            end

            // Capture each read response exactly once.
            if (state == WAIT_READ && read_valid) begin
                data_buffer <= read_data;
            end

            // Update addresses and counter only when
            // the write has been accepted.
            if (state == WRITE && write_ready) begin
                src_addr_reg <=
                    src_addr_reg + BYTES_PER_WORD;

                dst_addr_reg <=
                    dst_addr_reg + BYTES_PER_WORD;

                remaining_words <= remaining_words - 1'b1;
            end

            // Signal completion when entering DONE.
            if (next_state == DONE && state != DONE) begin
                done_reg <= 1'b1;
            end

        end
    end

    // --------------------------------------------------
    // Output logic
    // --------------------------------------------------

    always_comb begin
        read_req   = 1'b0;
        read_addr  = src_addr_reg;

        write_req  = 1'b0;
        write_addr = dst_addr_reg;
        write_data = data_buffer;

        busy = 1'b0;
        done = done_reg;
        irq  = done_reg;

        case (state)

            IDLE: begin
                busy = 1'b0;
            end

            READ: begin
                busy     = 1'b1;
                read_req = 1'b1;
            end

            WAIT_READ: begin
                busy = 1'b1;
            end

            WRITE: begin
                busy      = 1'b1;
                write_req = 1'b1;
            end

            CHECK: begin
                busy = 1'b1;
            end

            DONE: begin
                busy = 1'b0;
            end

            default: begin
                busy = 1'b0;
            end

        endcase
    end

endmodule
