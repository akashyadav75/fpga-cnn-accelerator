
/*-------------------------------------------------------------------
 *  Module: comparator
 *  Fixed bugs:
 *  1. buf_idx and delay_cnt now reset when a new image starts
 *  2. Decision is computed from buffer values directly (combinational
 *     ArgMax) so it is stable when valid_out is asserted - no stale
 *     pipeline read.
 *  3. state and delay_cnt reset after valid_out fires so the module
 *     is ready for the next image.
 *------------------------------------------------------------------*/

module comparator
    (
        input  wire        clk,
        input  wire        rst_n,
        input  wire        valid_in,
        input  wire [11:0] data_in,
        output reg  [3:0]  decision,
        output reg         valid_out
    );

    reg signed [11:0] buffer [0:9];
    reg [3:0]  buf_idx;
    reg [3:0]  delay_cnt;
    reg        state;

    // -------------------------------------------------------
    // Combinational ArgMax over the 10 stored scores.
    // Using a priority-encoded if-else so Vivado infers a
    // balanced LUT tree (no long carry chain needed).
    // -------------------------------------------------------
    reg signed [11:0] max_comb;
    reg        [3:0]  dec_comb;
    integer k;
    always @(*)
    begin
        max_comb = buffer[0];
        dec_comb = 4'd0;
        for (k = 1; k <= 9; k = k + 1)
        begin
            if (buffer[k] > max_comb)
            begin
                max_comb = buffer[k];
                dec_comb = k[3:0];
            end
        end
    end

    always @(posedge clk)
    begin
        if (~rst_n)
        begin
            valid_out  <= 0;
            buf_idx    <= 0;
            delay_cnt  <= 0;
            state      <= 0;
            decision   <= 4'd0;
            buffer[0]  <= 12'd0; buffer[1]  <= 12'd0;
            buffer[2]  <= 12'd0; buffer[3]  <= 12'd0;
            buffer[4]  <= 12'd0; buffer[5]  <= 12'd0;
            buffer[6]  <= 12'd0; buffer[7]  <= 12'd0;
            buffer[8]  <= 12'd0; buffer[9]  <= 12'd0;
        end
        else
        begin
            valid_out <= 0; // default de-assert

            if (valid_in)
            begin
                // A new stream of FC outputs is arriving.
                // Reset buf_idx on the very first beat so we always
                // start filling from index 0, regardless of what
                // happened in the previous image.
                if (state == 0)
                    buf_idx <= 0;

                buffer[buf_idx] <= data_in;
                buf_idx <= buf_idx + 1'b1;

                if (buf_idx == 4'd9)
                begin
                    state     <= 1;
                    buf_idx   <= 0;   // ready for next image
                    delay_cnt <= 0;
                end
            end
            else if (state == 1)
            begin
                // Wait a few cycles for the combinational ArgMax
                // to settle, then latch and assert valid_out.
                delay_cnt <= delay_cnt + 1'b1;

                if (delay_cnt == 4'd2)
                begin
                    decision  <= dec_comb;  // latch stable ArgMax
                    valid_out <= 1'b1;
                    state     <= 0;         // reset for next image
                    delay_cnt <= 0;
                end
            end
        end
    end

endmodule
