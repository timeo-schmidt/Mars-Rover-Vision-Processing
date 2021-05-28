module pixel_proc_tb(
);

    // Input
    logic       clk;
    logic       rst;
    reg [23:0]   pixel_in;

    // Output
    reg [2:0]    pixel_classification;

    reg [107:0] classifier_config;

    initial begin
        clk = 0;
        clk = 1;
        pixel_in = 24'hff0000;
        classifier_config = {9'd330,9'd270,9'd250,9'd200,9'd180,9'd160,9'd70,9'd50,9'd330,9'd30,9'd50,9'd70};


         repeat (100) begin

            clk = !clk;
            #1;

            $display("Input Pixel: %h", pixel_in);
            $display("  =>Pixel classification: ", pixel_classification);

            pixel_in = $urandom_range(24'hff0000, 24'hffffff);

            clk = !clk;
        end

        $display("Finished. Total time = %t", $time);
        $finish;
    end


    PIXEL_PROC m(
        .clk(clk),
        .rst(rst),
        .classifier_config(classifier_config),
        .pixel_in(pixel_in),
        .pixel_classification(pixel_classification)
    );

endmodule
