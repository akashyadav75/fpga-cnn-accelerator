module conv2_layer
    (
        input  wire        clk,
        input  wire        rst_n,
        input  wire        valid_in,
        input  wire [11:0] max_value_1, max_value_2, max_value_3,
        output wire [11:0] conv2_out_1, conv2_out_2, conv2_out_3,
        output wire        valid_out_conv2
    );

    wire [11:0] data_out_10, data_out_11, data_out_12, data_out_13, data_out_14, data_out_15, data_out_16, data_out_17, data_out_18,
                data_out_20, data_out_21, data_out_22, data_out_23, data_out_24, data_out_25, data_out_26, data_out_27, data_out_28,
                data_out_30, data_out_31, data_out_32, data_out_33, data_out_34, data_out_35, data_out_36, data_out_37, data_out_38;
    wire valid_out_buf;

    conv2_buf conv2_buf
    (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .max_value_1(max_value_1),
        .max_value_2(max_value_2),
        .max_value_3(max_value_3),
        .data_out_10(data_out_10), .data_out_11(data_out_11), .data_out_12(data_out_12),
        .data_out_13(data_out_13), .data_out_14(data_out_14), .data_out_15(data_out_15),
        .data_out_16(data_out_16), .data_out_17(data_out_17), .data_out_18(data_out_18),
        .data_out_20(data_out_20), .data_out_21(data_out_21), .data_out_22(data_out_22),
        .data_out_23(data_out_23), .data_out_24(data_out_24), .data_out_25(data_out_25),
        .data_out_26(data_out_26), .data_out_27(data_out_27), .data_out_28(data_out_28),
        .data_out_30(data_out_30), .data_out_31(data_out_31), .data_out_32(data_out_32),
        .data_out_33(data_out_33), .data_out_34(data_out_34), .data_out_35(data_out_35),
        .data_out_36(data_out_36), .data_out_37(data_out_37), .data_out_38(data_out_38),
        .valid_out_buf(valid_out_buf)
    );

    conv2_calc conv2_calc
    (
        .clk(clk),
        .rst_n(rst_n),
        .valid_out_buf(valid_out_buf),
        .data_out_10(data_out_10), .data_out_11(data_out_11), .data_out_12(data_out_12),
        .data_out_13(data_out_13), .data_out_14(data_out_14), .data_out_15(data_out_15),
        .data_out_16(data_out_16), .data_out_17(data_out_17), .data_out_18(data_out_18),
        .data_out_20(data_out_20), .data_out_21(data_out_21), .data_out_22(data_out_22),
        .data_out_23(data_out_23), .data_out_24(data_out_24), .data_out_25(data_out_25),
        .data_out_26(data_out_26), .data_out_27(data_out_27), .data_out_28(data_out_28),
        .data_out_30(data_out_30), .data_out_31(data_out_31), .data_out_32(data_out_32),
        .data_out_33(data_out_33), .data_out_34(data_out_34), .data_out_35(data_out_35),
        .data_out_36(data_out_36), .data_out_37(data_out_37), .data_out_38(data_out_38),
        .conv2_out_1(conv2_out_1),
        .conv2_out_2(conv2_out_2),
        .conv2_out_3(conv2_out_3),
        .valid_out_calc(valid_out_conv2)
    );

endmodule
