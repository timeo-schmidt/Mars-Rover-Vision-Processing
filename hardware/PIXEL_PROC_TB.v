module pixel_proc_tb(
);

    // Input
    logic       clk;
    logic       rst;
    reg[23:0]   pixel_in;

    // Output
    reg[2:0]    pixel_classification;

    initial begin
        clk = 0;
        clk = 1;
        pixel_in = 0;

         repeat (100) begin

            clk = !clk;
            #1;

            $display("Input Pixel: %h", pixel_in);
            $display("  =>Pixel classification: ", pixel_classification);

            pixel_in = $urandom_range(24'h000000, 24'hffffff);

            clk = !clk;
        end

        $display("Finished. Total time = %t", $time);
        $finish;
    end


    PIXEL_PROC m(
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .pixel_classification(pixel_classification)
    );

endmodule
