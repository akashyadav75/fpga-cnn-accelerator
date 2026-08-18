// verification/tb/top_tb.v
`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst_n;
    
    reg [7:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    
    wire [3:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    reg m_axis_tready;

    // Instantiate Top Module
    axis_cnn_mnist uut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock generator (100 MHz)
    always #5 clk = ~clk;

    // Buffer to hold test image (28x28 = 784 pixels)
    reg [7:0] test_image [0:783];
    integer i;

    initial begin
        clk = 0;
        rst_n = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        
        #100;
        rst_n = 1;
        #50;

        // Load image (digit 7)
        $readmemh("verification/tb/data/img_0_label_7.mem", test_image);
        
        $display("[TB] Starting transmission of MNIST Image...");
        
        for (i = 0; i < 784; i = i + 1) begin
            @(posedge clk);
            s_axis_tdata = test_image[i];
            s_axis_tvalid = 1;
            if (i == 783) begin
                s_axis_tlast = 1;
            end
        end
        
        @(posedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        
        $display("[TB] Stream finished. Waiting for inference...");
        
        // Wait for prediction
        @(posedge m_axis_tvalid);
        $display("[TB] Prediction Received!");
        $display("[TB] Predicted Class: %d (Expected: 7)", m_axis_tdata);
        
        #100;
        $finish;
    end
endmodule
