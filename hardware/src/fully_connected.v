module fully_connected
    #(
        parameter INPUT_NUM = 48,
                  OUTPUT_NUM = 10,
                  DATA_BITS = 8
    )
    (
        input  wire              clk,
        input  wire              rst_n,
        input  wire              valid_in,
        input  wire signed [11:0] data_in_1, data_in_2, data_in_3,
        output reg  signed [11:0] data_out,
        output reg               valid_out_fc
    );

    reg signed [7:0] weight [0:INPUT_NUM*OUTPUT_NUM-1];
    reg signed [7:0] bias [0:OUTPUT_NUM-1];
    
    initial
    begin
        $readmemh("fc_weight.mem", weight);
        $readmemh("fc_bias.mem", bias);
    end

    reg [5:0]  state;
    reg [23:0] acc;
    reg [5:0]  w_idx;
    reg [3:0]  b_idx;

    always @(posedge clk)
    begin
        if (~rst_n)
        begin
            state <= 0;
            acc <= 0;
            w_idx <= 0;
            b_idx <= 0;
            data_out <= 0;
            valid_out_fc <= 0;
        end
        else
        begin
            if (valid_in)
            begin
                state <= state + 1'b1;

                if (state < 16)
                begin
                    acc <= acc + data_in_1 * weight[w_idx + b_idx * INPUT_NUM] +
                                 data_in_2 * weight[w_idx + 16 + b_idx * INPUT_NUM] +
                                 data_in_3 * weight[w_idx + 32 + b_idx * INPUT_NUM];
                    w_idx <= w_idx + 1'b1;
                end

                if (state == 16)
                begin
                    state <= 0;
                    w_idx <= 0;
                    b_idx <= b_idx + 1'b1;
                    
                    // Add bias (scaled by <<< 4)
                    acc <= acc + (bias[b_idx] <<< 4);
                end
            end

            if (state == 16)
            begin
                valid_out_fc <= 1'b1;
                // Clip output to 12-bit signed range [-2048, 2047]
                if (acc[23:4] > 2047)
                begin
                    data_out <= 2047;
                end
                else if (acc[23:4] < -2048)
                begin
                    data_out <= -2048;
                end
                else
                begin
                    data_out <= acc[15:4];
                end
                acc <= 0;
            end
            else
            begin
                valid_out_fc <= 0;
            end

            if (b_idx == 10)
            begin
                b_idx <= 0;
            end
        end
    end

endmodule
