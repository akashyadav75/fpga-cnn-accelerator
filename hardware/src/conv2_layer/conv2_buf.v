module conv2_buf
    #(
        parameter WIDTH = 12,
                  HEIGHT = 12,
                  DATA_BITS = 12
    )
    (
        input  wire                 clk,
        input  wire                 rst_n,
        input  wire                 valid_in,
        input  wire [DATA_BITS-1:0] max_value_1, max_value_2, max_value_3,
        output reg  [DATA_BITS-1:0] data_out_10, data_out_11, data_out_12,
                                    data_out_13, data_out_14, data_out_15,
                                    data_out_16, data_out_17, data_out_18,
                                    data_out_20, data_out_21, data_out_22,
                                    data_out_23, data_out_24, data_out_25,
                                    data_out_26, data_out_27, data_out_28,
                                    data_out_30, data_out_31, data_out_32,
                                    data_out_33, data_out_34, data_out_35,
                                    data_out_36, data_out_37, data_out_38,
        output reg                  valid_out_buf
    );

    localparam FILTER_SIZE = 3;

    reg [DATA_BITS-1:0] buffer_1 [0:WIDTH*FILTER_SIZE-1];
    reg [DATA_BITS-1:0] buffer_2 [0:WIDTH*FILTER_SIZE-1];
    reg [DATA_BITS-1:0] buffer_3 [0:WIDTH*FILTER_SIZE-1];
    reg [DATA_BITS-1:0] buf_idx;
    reg [3:0]           w_idx, h_idx;
    reg [1:0]           buf_flag; // 0 ~ 2
    reg                 state;

    integer i;

    always @(posedge clk)
    begin
        if (~rst_n)
        begin
            for (i=0; i <= WIDTH*FILTER_SIZE-1; i=i+1)
            begin
                buffer_1[i] <= 0;
                buffer_2[i] <= 0;
                buffer_3[i] <= 0;
            end
            buf_idx <= 0;
            w_idx <= 0;
            h_idx <= 0;
            buf_flag <= 0;
            state <= 0;
            valid_out_buf <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0;
            data_out_13 <= 0; data_out_14 <= 0; data_out_15 <= 0;
            data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0;
            data_out_23 <= 0; data_out_24 <= 0; data_out_25 <= 0;
            data_out_26 <= 0; data_out_27 <= 0; data_out_28 <= 0;
            data_out_30 <= 0; data_out_31 <= 0; data_out_32 <= 0;
            data_out_33 <= 0; data_out_34 <= 0; data_out_35 <= 0;
            data_out_36 <= 0; data_out_37 <= 0; data_out_38 <= 0;
        end
        else
        begin
            if (valid_in)
            begin
                buf_idx <= buf_idx + 1;
                if (buf_idx == WIDTH*FILTER_SIZE-1)
                begin // size = 36 = 12(w) * 3(h)
                    buf_idx <= 0;
                end

                buffer_1[buf_idx] <= max_value_1;
                buffer_2[buf_idx] <= max_value_2;
                buffer_3[buf_idx] <= max_value_3;

                // Wait until first 36 input data filled in buffer
                if (!state)
                begin
                    if (buf_idx == WIDTH*FILTER_SIZE-1)
                    begin
                        state <= 1'b1;
                    end
                end
                else
                begin // valid state
                    w_idx <= w_idx + 1'b1; // move right

                    if (w_idx == WIDTH-FILTER_SIZE+1)
                    begin
                        valid_out_buf <= 1'b0; // unvalid area
                    end
                    else if (w_idx == WIDTH-1)
                    begin
                        buf_flag <= buf_flag + 1'b1;
                        if (buf_flag == FILTER_SIZE-1)
                        begin
                            buf_flag <= 0;
                        end
                        w_idx <= 0;

                        if (h_idx == HEIGHT-FILTER_SIZE)
                        begin  // done 1 input read -> 12 * 12
                            h_idx <= 0;
                            state <= 1'b0;
                        end 
                        h_idx <= h_idx + 1'b1;
                    end
                    else if (w_idx == 0)
                    begin
                        valid_out_buf <= 1'b1; // start valid area
                    end

                    // Buffer Selection -> 3 * 3
                    if (buf_flag == 2'd0)
                    begin
                        data_out_10 <= buffer_1[w_idx];
                        data_out_11 <= buffer_1[w_idx + 1];
                        data_out_12 <= buffer_1[w_idx + 2];
                        data_out_13 <= buffer_1[w_idx + WIDTH];
                        data_out_14 <= buffer_1[w_idx + 1 + WIDTH];
                        data_out_15 <= buffer_1[w_idx + 2 + WIDTH];
                        data_out_16 <= buffer_1[w_idx + WIDTH * 2];
                        data_out_17 <= buffer_1[w_idx + 1 + WIDTH * 2];
                        data_out_18 <= buffer_1[w_idx + 2 + WIDTH * 2];

                        data_out_20 <= buffer_2[w_idx];
                        data_out_21 <= buffer_2[w_idx + 1];
                        data_out_22 <= buffer_2[w_idx + 2];
                        data_out_23 <= buffer_2[w_idx + WIDTH];
                        data_out_24 <= buffer_2[w_idx + 1 + WIDTH];
                        data_out_25 <= buffer_2[w_idx + 2 + WIDTH];
                        data_out_26 <= buffer_2[w_idx + WIDTH * 2];
                        data_out_27 <= buffer_2[w_idx + 1 + WIDTH * 2];
                        data_out_28 <= buffer_2[w_idx + 2 + WIDTH * 2];

                        data_out_30 <= buffer_3[w_idx];
                        data_out_31 <= buffer_3[w_idx + 1];
                        data_out_32 <= buffer_3[w_idx + 2];
                        data_out_33 <= buffer_3[w_idx + WIDTH];
                        data_out_34 <= buffer_3[w_idx + 1 + WIDTH];
                        data_out_35 <= buffer_3[w_idx + 2 + WIDTH];
                        data_out_36 <= buffer_3[w_idx + WIDTH * 2];
                        data_out_37 <= buffer_3[w_idx + 1 + WIDTH * 2];
                        data_out_38 <= buffer_3[w_idx + 2 + WIDTH * 2];
                    end
                    else if (buf_flag == 2'd1)
                    begin
                        data_out_10 <= buffer_1[w_idx + WIDTH];
                        data_out_11 <= buffer_1[w_idx + 1 + WIDTH];
                        data_out_12 <= buffer_1[w_idx + 2 + WIDTH];
                        data_out_13 <= buffer_1[w_idx + WIDTH * 2];
                        data_out_14 <= buffer_1[w_idx + 1 + WIDTH * 2];
                        data_out_15 <= buffer_1[w_idx + 2 + WIDTH * 2];
                        data_out_16 <= buffer_1[w_idx];
                        data_out_17 <= buffer_1[w_idx + 1];
                        data_out_18 <= buffer_1[w_idx + 2];

                        data_out_20 <= buffer_2[w_idx + WIDTH];
                        data_out_21 <= buffer_2[w_idx + 1 + WIDTH];
                        data_out_22 <= buffer_2[w_idx + 2 + WIDTH];
                        data_out_23 <= buffer_2[w_idx + WIDTH * 2];
                        data_out_24 <= buffer_2[w_idx + 1 + WIDTH * 2];
                        data_out_25 <= buffer_2[w_idx + 2 + WIDTH * 2];
                        data_out_26 <= buffer_2[w_idx];
                        data_out_27 <= buffer_2[w_idx + 1];
                        data_out_28 <= buffer_2[w_idx + 2];

                        data_out_30 <= buffer_3[w_idx + WIDTH];
                        data_out_31 <= buffer_3[w_idx + 1 + WIDTH];
                        data_out_32 <= buffer_3[w_idx + 2 + WIDTH];
                        data_out_33 <= buffer_3[w_idx + WIDTH * 2];
                        data_out_34 <= buffer_3[w_idx + 1 + WIDTH * 2];
                        data_out_35 <= buffer_3[w_idx + 2 + WIDTH * 2];
                        data_out_36 <= buffer_3[w_idx];
                        data_out_37 <= buffer_3[w_idx + 1];
                        data_out_38 <= buffer_3[w_idx + 2];
                    end
                    else if (buf_flag == 2'd2)
                    begin
                        data_out_10 <= buffer_1[w_idx + WIDTH * 2];
                        data_out_11 <= buffer_1[w_idx + 1 + WIDTH * 2];
                        data_out_12 <= buffer_1[w_idx + 2 + WIDTH * 2];
                        data_out_13 <= buffer_1[w_idx];
                        data_out_14 <= buffer_1[w_idx + 1];
                        data_out_15 <= buffer_1[w_idx + 2];
                        data_out_16 <= buffer_1[w_idx + WIDTH];
                        data_out_17 <= buffer_1[w_idx + 1 + WIDTH];
                        data_out_18 <= buffer_1[w_idx + 2 + WIDTH];

                        data_out_20 <= buffer_2[w_idx + WIDTH * 2];
                        data_out_21 <= buffer_2[w_idx + 1 + WIDTH * 2];
                        data_out_22 <= buffer_2[w_idx + 2 + WIDTH * 2];
                        data_out_23 <= buffer_2[w_idx];
                        data_out_24 <= buffer_2[w_idx + 1];
                        data_out_25 <= buffer_2[w_idx + 2];
                        data_out_26 <= buffer_2[w_idx + WIDTH];
                        data_out_27 <= buffer_2[w_idx + 1 + WIDTH];
                        data_out_28 <= buffer_2[w_idx + 2 + WIDTH];

                        data_out_30 <= buffer_3[w_idx + WIDTH * 2];
                        data_out_31 <= buffer_3[w_idx + 1 + WIDTH * 2];
                        data_out_32 <= buffer_3[w_idx + 2 + WIDTH * 2];
                        data_out_33 <= buffer_3[w_idx];
                        data_out_34 <= buffer_3[w_idx + 1];
                        data_out_35 <= buffer_3[w_idx + 2];
                        data_out_36 <= buffer_3[w_idx + WIDTH];
                        data_out_37 <= buffer_3[w_idx + 1 + WIDTH];
                        data_out_38 <= buffer_3[w_idx + 2 + WIDTH];
                    end
                end
            end
        end
    end

endmodule
