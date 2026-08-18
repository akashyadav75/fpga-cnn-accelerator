module conv1_calc
    #(
        parameter CONV_BIT = 12
    )
    (
        input  wire        clk,
        input  wire        rst_n,
        input  wire        valid_out_buf,
        input  wire [7:0]  data_out_0, data_out_1, data_out_2, data_out_3, data_out_4,
                           data_out_5, data_out_6, data_out_7, data_out_8, data_out_9,
                           data_out_10, data_out_11, data_out_12, data_out_13, data_out_14,
                           data_out_15, data_out_16, data_out_17, data_out_18, data_out_19,
                           data_out_20, data_out_21, data_out_22, data_out_23, data_out_24,
        output reg  [CONV_BIT-1:0] conv_out_1, conv_out_2, conv_out_3,
        output reg         valid_out_calc
    );

    reg signed [7:0] weight_1 [0:24];
    reg signed [7:0] weight_2 [0:24];
    reg signed [7:0] weight_3 [0:24];
    reg signed [7:0] bias_1, bias_2, bias_3;
    reg signed [7:0] bias [0:2];

    initial
    begin
        $readmemh("conv1_weight_1.mem", weight_1);
        $readmemh("conv1_weight_2.mem", weight_2);
        $readmemh("conv1_weight_3.mem", weight_3);
        $readmemh("conv1_bias.mem", bias);
    end

    always @(*)
    begin
        bias_1 = bias[0];
        bias_2 = bias[1];
        bias_3 = bias[2];
    end

    wire signed [15:0] mul_out_1 [0:24];
    wire signed [15:0] mul_out_2 [0:24];
    wire signed [15:0] mul_out_3 [0:24];

    assign mul_out_1[0] = $signed({1'b0, data_out_0}) * weight_1[0];
    assign mul_out_1[1] = $signed({1'b0, data_out_1}) * weight_1[1];
    assign mul_out_1[2] = $signed({1'b0, data_out_2}) * weight_1[2];
    assign mul_out_1[3] = $signed({1'b0, data_out_3}) * weight_1[3];
    assign mul_out_1[4] = $signed({1'b0, data_out_4}) * weight_1[4];
    assign mul_out_1[5] = $signed({1'b0, data_out_5}) * weight_1[5];
    assign mul_out_1[6] = $signed({1'b0, data_out_6}) * weight_1[6];
    assign mul_out_1[7] = $signed({1'b0, data_out_7}) * weight_1[7];
    assign mul_out_1[8] = $signed({1'b0, data_out_8}) * weight_1[8];
    assign mul_out_1[9] = $signed({1'b0, data_out_9}) * weight_1[9];
    assign mul_out_1[10] = $signed({1'b0, data_out_10}) * weight_1[10];
    assign mul_out_1[11] = $signed({1'b0, data_out_11}) * weight_1[11];
    assign mul_out_1[12] = $signed({1'b0, data_out_12}) * weight_1[12];
    assign mul_out_1[13] = $signed({1'b0, data_out_13}) * weight_1[13];
    assign mul_out_1[14] = $signed({1'b0, data_out_14}) * weight_1[14];
    assign mul_out_1[15] = $signed({1'b0, data_out_15}) * weight_1[15];
    assign mul_out_1[16] = $signed({1'b0, data_out_16}) * weight_1[16];
    assign mul_out_1[17] = $signed({1'b0, data_out_17}) * weight_1[17];
    assign mul_out_1[18] = $signed({1'b0, data_out_18}) * weight_1[18];
    assign mul_out_1[19] = $signed({1'b0, data_out_19}) * weight_1[19];
    assign mul_out_1[20] = $signed({1'b0, data_out_20}) * weight_1[20];
    assign mul_out_1[21] = $signed({1'b0, data_out_21}) * weight_1[21];
    assign mul_out_1[22] = $signed({1'b0, data_out_22}) * weight_1[22];
    assign mul_out_1[23] = $signed({1'b0, data_out_23}) * weight_1[23];
    assign mul_out_1[24] = $signed({1'b0, data_out_24}) * weight_1[24];

    assign mul_out_2[0] = $signed({1'b0, data_out_0}) * weight_2[0];
    assign mul_out_2[1] = $signed({1'b0, data_out_1}) * weight_2[1];
    assign mul_out_2[2] = $signed({1'b0, data_out_2}) * weight_2[2];
    assign mul_out_2[3] = $signed({1'b0, data_out_3}) * weight_2[3];
    assign mul_out_2[4] = $signed({1'b0, data_out_4}) * weight_2[4];
    assign mul_out_2[5] = $signed({1'b0, data_out_5}) * weight_2[5];
    assign mul_out_2[6] = $signed({1'b0, data_out_6}) * weight_2[6];
    assign mul_out_2[7] = $signed({1'b0, data_out_7}) * weight_2[7];
    assign mul_out_2[8] = $signed({1'b0, data_out_8}) * weight_2[8];
    assign mul_out_2[9] = $signed({1'b0, data_out_9}) * weight_2[9];
    assign mul_out_2[10] = $signed({1'b0, data_out_10}) * weight_2[10];
    assign mul_out_2[11] = $signed({1'b0, data_out_11}) * weight_2[11];
    assign mul_out_2[12] = $signed({1'b0, data_out_12}) * weight_2[12];
    assign mul_out_2[13] = $signed({1'b0, data_out_13}) * weight_2[13];
    assign mul_out_2[14] = $signed({1'b0, data_out_14}) * weight_2[14];
    assign mul_out_2[15] = $signed({1'b0, data_out_15}) * weight_2[15];
    assign mul_out_2[16] = $signed({1'b0, data_out_16}) * weight_2[16];
    assign mul_out_2[17] = $signed({1'b0, data_out_17}) * weight_2[17];
    assign mul_out_2[18] = $signed({1'b0, data_out_18}) * weight_2[18];
    assign mul_out_2[19] = $signed({1'b0, data_out_19}) * weight_2[19];
    assign mul_out_2[20] = $signed({1'b0, data_out_20}) * weight_2[20];
    assign mul_out_2[21] = $signed({1'b0, data_out_21}) * weight_2[21];
    assign mul_out_2[22] = $signed({1'b0, data_out_22}) * weight_2[22];
    assign mul_out_2[23] = $signed({1'b0, data_out_23}) * weight_2[23];
    assign mul_out_2[24] = $signed({1'b0, data_out_24}) * weight_2[24];

    assign mul_out_3[0] = $signed({1'b0, data_out_0}) * weight_3[0];
    assign mul_out_3[1] = $signed({1'b0, data_out_1}) * weight_3[1];
    assign mul_out_3[2] = $signed({1'b0, data_out_2}) * weight_3[2];
    assign mul_out_3[3] = $signed({1'b0, data_out_3}) * weight_3[3];
    assign mul_out_3[4] = $signed({1'b0, data_out_4}) * weight_3[4];
    assign mul_out_3[5] = $signed({1'b0, data_out_5}) * weight_3[5];
    assign mul_out_3[6] = $signed({1'b0, data_out_6}) * weight_3[6];
    assign mul_out_3[7] = $signed({1'b0, data_out_7}) * weight_3[7];
    assign mul_out_3[8] = $signed({1'b0, data_out_8}) * weight_3[8];
    assign mul_out_3[9] = $signed({1'b0, data_out_9}) * weight_3[9];
    assign mul_out_3[10] = $signed({1'b0, data_out_10}) * weight_3[10];
    assign mul_out_3[11] = $signed({1'b0, data_out_11}) * weight_3[11];
    assign mul_out_3[12] = $signed({1'b0, data_out_12}) * weight_3[12];
    assign mul_out_3[13] = $signed({1'b0, data_out_13}) * weight_3[13];
    assign mul_out_3[14] = $signed({1'b0, data_out_14}) * weight_3[14];
    assign mul_out_3[15] = $signed({1'b0, data_out_15}) * weight_3[15];
    assign mul_out_3[16] = $signed({1'b0, data_out_16}) * weight_3[16];
    assign mul_out_3[17] = $signed({1'b0, data_out_17}) * weight_3[17];
    assign mul_out_3[18] = $signed({1'b0, data_out_18}) * weight_3[18];
    assign mul_out_3[19] = $signed({1'b0, data_out_19}) * weight_3[19];
    assign mul_out_3[20] = $signed({1'b0, data_out_20}) * weight_3[20];
    assign mul_out_3[21] = $signed({1'b0, data_out_21}) * weight_3[21];
    assign mul_out_3[22] = $signed({1'b0, data_out_22}) * weight_3[22];
    assign mul_out_3[23] = $signed({1'b0, data_out_23}) * weight_3[23];
    assign mul_out_3[24] = $signed({1'b0, data_out_24}) * weight_3[24];

    wire signed [21:0] sum_1, sum_2, sum_3;

    assign sum_1 = mul_out_1[0] + mul_out_1[1] + mul_out_1[2] + mul_out_1[3] + mul_out_1[4] +
                   mul_out_1[5] + mul_out_1[6] + mul_out_1[7] + mul_out_1[8] + mul_out_1[9] +
                   mul_out_1[10] + mul_out_1[11] + mul_out_1[12] + mul_out_1[13] + mul_out_1[14] +
                   mul_out_1[15] + mul_out_1[16] + mul_out_1[17] + mul_out_1[18] + mul_out_1[19] +
                   mul_out_1[20] + mul_out_1[21] + mul_out_1[22] + mul_out_1[23] + mul_out_1[24] + (bias_1 <<< 4);

    assign sum_2 = mul_out_2[0] + mul_out_2[1] + mul_out_2[2] + mul_out_2[3] + mul_out_2[4] +
                   mul_out_2[5] + mul_out_2[6] + mul_out_2[7] + mul_out_2[8] + mul_out_2[9] +
                   mul_out_2[10] + mul_out_2[11] + mul_out_2[12] + mul_out_2[13] + mul_out_2[14] +
                   mul_out_2[15] + mul_out_2[16] + mul_out_2[17] + mul_out_2[18] + mul_out_2[19] +
                   mul_out_2[20] + mul_out_2[21] + mul_out_2[22] + mul_out_2[23] + mul_out_2[24] + (bias_2 <<< 4);

    assign sum_3 = mul_out_3[0] + mul_out_3[1] + mul_out_3[2] + mul_out_3[3] + mul_out_3[4] +
                   mul_out_3[5] + mul_out_3[6] + mul_out_3[7] + mul_out_3[8] + mul_out_3[9] +
                   mul_out_3[10] + mul_out_3[11] + mul_out_3[12] + mul_out_3[13] + mul_out_3[14] +
                   mul_out_3[15] + mul_out_3[16] + mul_out_3[17] + mul_out_3[18] + mul_out_3[19] +
                   mul_out_3[20] + mul_out_3[21] + mul_out_3[22] + mul_out_3[23] + mul_out_3[24] + (bias_3 <<< 4);

    always @(posedge clk)
    begin
        if (~rst_n)
        begin
            conv_out_1 <= 0;
            conv_out_2 <= 0;
            conv_out_3 <= 0;
            valid_out_calc <= 0;
        end
        else
        begin
            valid_out_calc <= valid_out_buf;
            if (valid_out_buf)
            begin
                // sum_1 is signed 22-bit, shift right by 4 (to divide by 16) and clip to 12-bit signed range [-2048, 2047]
                if (sum_1[21:4] > 2047)
                begin
                    conv_out_1 <= 2047;
                end
                else if (sum_1[21:4] < -2048)
                begin
                    conv_out_1 <= -2048;
                end
                else
                begin
                    conv_out_1 <= sum_1[15:4];
                end

                if (sum_2[21:4] > 2047)
                begin
                    conv_out_2 <= 2047;
                end
                else if (sum_2[21:4] < -2048)
                begin
                    conv_out_2 <= -2048;
                end
                else
                begin
                    conv_out_2 <= sum_2[15:4];
                end

                if (sum_3[21:4] > 2047)
                begin
                    conv_out_3 <= 2047;
                end
                else if (sum_3[21:4] < -2048)
                begin
                    conv_out_3 <= -2048;
                end
                else
                begin
                    conv_out_3 <= sum_3[15:4];
                end
            end
        end
    end

endmodule
