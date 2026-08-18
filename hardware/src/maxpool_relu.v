module maxpool_relu
    #(
        parameter CONV_BIT = 12,
                  HALF_WIDTH = 12,
                  HALF_HEIGHT = 12,
                  HALF_WIDTH_BIT = 4
    )
    (
        input  wire                clk,
        input  wire                rst_n,
        input  wire                valid_in,
        input  wire [CONV_BIT-1:0] conv_out_1, conv_out_2, conv_out_3,
        output reg  [CONV_BIT-1:0] max_value_1, max_value_2, max_value_3,
        output reg                 valid_out_relu
    );

    reg [CONV_BIT-1:0] line_buffer_1 [0:HALF_WIDTH*2-1];
    reg [CONV_BIT-1:0] line_buffer_2 [0:HALF_WIDTH*2-1];
    reg [CONV_BIT-1:0] line_buffer_3 [0:HALF_WIDTH*2-1];
    
    reg [HALF_WIDTH_BIT:0] w_idx;
    reg [HALF_WIDTH_BIT:0] h_idx;
    reg                    state;
    reg                    buf_flag; // 0 ~ 1

    integer i;

    always @(posedge clk)
    begin
        if (~rst_n)
        begin
            for (i=0; i <= HALF_WIDTH*2-1; i=i+1)
            begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
                line_buffer_3[i] <= 0;
            end
            w_idx <= 0;
            h_idx <= 0;
            state <= 0;
            buf_flag <= 0;
            valid_out_relu <= 0;
            max_value_1 <= 0;
            max_value_2 <= 0;
            max_value_3 <= 0;
        end
        else
        begin
            if (valid_in)
            begin
                w_idx <= w_idx + 1'b1;

                if (buf_flag == 1'b0)
                begin
                    line_buffer_1[w_idx] <= conv_out_1;
                    line_buffer_2[w_idx] <= conv_out_2;
                    line_buffer_3[w_idx] <= conv_out_3;
                end

                if (w_idx == HALF_WIDTH*2-1)
                begin
                    w_idx <= 0;
                    buf_flag <= buf_flag + 1'b1;

                    if (buf_flag == 1'b1)
                    begin
                        buf_flag <= 0;
                    end

                    if (h_idx == HALF_HEIGHT*2-1)
                    begin
                        h_idx <= 0;
                    end
                    else
                    begin
                        h_idx <= h_idx + 1'b1;
                    end
                end

                if (h_idx % 2 == 1 && w_idx % 2 == 1)
                begin
                    valid_out_relu <= 1'b1;

                    // Channel 1
                    if (conv_out_1 > line_buffer_1[w_idx-1] && conv_out_1 > line_buffer_1[w_idx] && conv_out_1 > conv_out_1) // simplified max
                    begin
                        max_value_1 <= (conv_out_1 > 0) ? conv_out_1 : 0;
                    end
                    else if (line_buffer_1[w_idx-1] > line_buffer_1[w_idx] && line_buffer_1[w_idx-1] > conv_out_1)
                    begin
                        max_value_1 <= (line_buffer_1[w_idx-1] > 0) ? line_buffer_1[w_idx-1] : 0;
                    end
                    else
                    begin
                        max_value_1 <= (line_buffer_1[w_idx] > 0) ? line_buffer_1[w_idx] : 0;
                    end

                    // Channel 2
                    if (conv_out_2 > line_buffer_2[w_idx-1] && conv_out_2 > line_buffer_2[w_idx] && conv_out_2 > conv_out_2)
                    begin
                        max_value_2 <= (conv_out_2 > 0) ? conv_out_2 : 0;
                    end
                    else if (line_buffer_2[w_idx-1] > line_buffer_2[w_idx] && line_buffer_2[w_idx-1] > conv_out_2)
                    begin
                        max_value_2 <= (line_buffer_2[w_idx-1] > 0) ? line_buffer_2[w_idx-1] : 0;
                    end
                    else
                    begin
                        max_value_2 <= (line_buffer_2[w_idx] > 0) ? line_buffer_2[w_idx] : 0;
                    end

                    // Channel 3
                    if (conv_out_3 > line_buffer_3[w_idx-1] && conv_out_3 > line_buffer_3[w_idx] && conv_out_3 > conv_out_3)
                    begin
                        max_value_3 <= (conv_out_3 > 0) ? conv_out_3 : 0;
                    end
                    else if (line_buffer_3[w_idx-1] > line_buffer_3[w_idx] && line_buffer_3[w_idx-1] > conv_out_3)
                    begin
                        max_value_3 <= (line_buffer_3[w_idx-1] > 0) ? line_buffer_3[w_idx-1] : 0;
                    end
                    else
                    begin
                        max_value_3 <= (line_buffer_3[w_idx] > 0) ? line_buffer_3[w_idx] : 0;
                    end
                end
                else
                begin
                    valid_out_relu <= 0;
                end
            end
            else
            begin
                valid_out_relu <= 0;
            end
        end
    end

endmodule
